# A collision object is generated when a compare(repair) is performed, or a create/update fails.
# It represents a comparison of the host's attributes and the contents of the DNS and DHCP network databases.
# When a repair operation has been requested then we know that the host already exists and should have all
# netdb entries present. This is flagged by repairing == true. Conversely, if we are being called as part of
# a create/update operation then we know that all entries should be cleared as we are intending to create them.
# This is flagged by clearing? == true
#
# DNS Collisions and Omissions
# A host's name is in collision if we can nslookup name
# A host's ip   is in collision if we can nslookup ip
# If we were able to lookup the host's name then we were given the ip address that this returned. If this address
# can be looked up then we have a secondary name collision. Following these secondary collisions ensures that we
# do not leave any dangling A records if we delete a name, and the same logic goes for a secondary ip collision
#
# Query structure dns_<keyType>_{entry,collision}
# E.G. dns_ip_entry is the hostname that is returned when dns is queried for this host's ip
# E.G. dns_ip_collision is the hostname that is returned when the dns entry does not match this hosts name OR false
# Query structure dhcp_<keyType>_<returnType>_{entry,collision}
# E.G. dhcp_mac_ip_entry is the ip that is retrieved from the DHCP entry that was looked up via host's MAC address
#

class Hostext::Collision
  # TODO: Use method_missing to rationalize this class
  attr_accessor :host, :dns, :dhcp
  attr_reader :dns_ip_missing, :dns_name_missing
  attr_reader :dhcp_entry_missing
  attr_reader :dns_ip_entry_host, :dns_name_entry_host
  attr_reader :dns_ip_secondary_entry_host, :dns_name_secondary_entry_host
  attr_reader :dhcp_mac_entry_host

  attr_reader :check, :repairing
  @@attribute_map = {"12" => "name"}

  # It is not good practice to store an ActiveRecord in the session so use our own mini host
  class Host < OpenStruct;   end

  # Create a new Collision
  # [+host+]: the AR host record
  # [+dns+] : Hash containing DNS entries
  # [+DHCP+]: Hash containing dhcp options for this mac address
  def initialize host, dns, dhcp
    @host  = Host.new host.attributes
    @dns   = dns
    @dhcp  = dhcp
    @check = rand 10000
    @repairing = false
    @dns_ip_missing = @dns_name_missing = @dhcp_entry_missing= false

    # Convert DHCP attribute values into names
    for key in @@attribute_map.keys
      dhcp[@@attribute_map[key]] = dhcp.delete key if dhcp.has_key? key
    end
  end

  def clearing?
    !repairing
  end

  def dhcp_mac_ip_collision
    dhcp_mac_ip_entry and dhcp_mac_ip_entry != host.ip ? dhcp_mac_ip_entry : false
  end
  def dhcp_mac_ip_entry
    dhcp["ip"] ? dhcp["ip"] : false
  end

  def dhcp_mac_ip_collision_info
    return false unless dhcp_mac_ip_collision
    hostname(host.mac) + " owned by " + dhcp_mac_owner
  end

  # The hosts that we overlap.
  def hosts
    [foreman_host(:dhcp, :mac_ip),
     foreman_host(:dns, :name), foreman_host(:dns, :name_secondary),
     foreman_host(:dns, :ip),   foreman_host(:dns, :ip_secondary)].compact.sort.uniq
  end

  # The hosts that we overlap but not including self.
  def collision_hosts
    host.marshal_dump[:id] ? hosts - [::Host.find host.marshal_dump[:id]] : hosts
  end

  def inv db, kind
    kind = kind.dup
    return kind.sub(/_.*/, "") if kind =~ /secondary/
    kind.sub!(/_.*/, "")
    (kind.sub!(/mac/, "ip") or kind.sub!(/ip/, "mac")) if db == "dhcp"
    (kind.sub!(/name/, "ip") or kind.sub!(/ip/, "name" )) if db == "dns"
    kind
  end

  # Returns the AR Host corresponding to the <db>_<kind>_entry information OR nil
  # E.G. foreman_host(:dns, :name)
  #   lookup the entry => Host.find_by_ip dns_name_entry
  #   Also does some caching for performance
  def foreman_host db, kind
    db   = db.to_s
    kind = kind.to_s
    return nil unless eval "#{db}_#{kind}_entry"
    inv_kind =(inv db, kind)
    (eval "@#{db}_#{kind}_entry_host ||= ::Host.find_by_#{inv_kind}(#{db}_#{kind}_entry)") || nil
  end

  # Returns the Foreman owner of a host using the <db>_<kind>_entry
  def owner db, kind
    existing_host = foreman_host db, kind
    existing_host ? existing_host.owner.name : "unknown"
  end

  def hostname mac
    hname = dhcp[mac].try(:[], "name")
    hname ? hname : "Unnamed host"
  end

  def dhcp_mac_owner; owner :dhcp, :mac_ip; end
  def dns_ip_owner;   owner :dns,  :ip;  end
  def dns_name_owner; owner :dns,  :name; end
  def dns_ip_secondary_owner;   owner :dns,  :ip_secondary;  end
  def dns_name_secondary_owner; owner :dns,  :name_secondary; end

  # The hostname of the machine that is using our desired IP address
  def dns_ip_collision
    dns_ip_entry and dns_ip_entry != host.name ? dns_ip_entry : false
  end
  def dns_ip_entry
    dns[host.ip]
  end

  # The IP address of the machine that is using our desired hostname
  def dns_name_collision
    dns_name_entry and dns_name_entry != host.ip ? dns_name_entry : false
  end
  def dns_name_entry
    dns[host.name]
  end

  # If we choose to remove the hostname record for our desired IP
  # the we should also remove the IP address of that machine as well
  def dns_ip_secondary_collision
    dns_ip_secondary_entry and (dns_ip_secondary_entry != host.ip or dns_ip_entry != host.name) ? dns_ip_secondary_entry : false
  end
  def dns_ip_secondary_entry
    return nil unless dns.has_key? host.ip
    dns[dns[host.ip]]
  end

  # If we choose to remove the IP record for our desired hostname
  # the we should also remove the hostname of that machine as well
  def dns_name_secondary_collision
    dns_name_secondary_entry and (dns_name_secondary_entry != host.name or dns_name_entry != host.ip) ? dns_name_secondary_entry : false
  end
  def dns_name_secondary_entry
    return nil unless dns.has_key? host.name
    dns[dns[host.name]]
  end

  # Are there any DNS collisions?
  def dns_collisions?
    dns_ip_collision or dns_ip_secondary_collision or dns_name_collision or dns_name_secondary_collision
  end

  # Are there any DHCP collisions?
  def dhcp_collisions?
    dhcp_mac_ip_collision
  end

  def empty?
    !dns? and !dhcp?
  end

  def no_issues?
    !dhcp_collisions? and !dns_collisions? and !dns_name_missing and !dns_ip_missing and !dhcp_entry_missing
  end

  # This is called on validation so we calculate missing and malformed entries
  def calculate
    @dns_name_missing   = dns[host.name] == false
    @dns_ip_missing     = dns[host.ip]   == false
    @dhcp_entry_missing = dhcp[host.mac] == nil
    @repairing          = true
  end
end
