class Collision
  # TODO: Use method_missing to rationalize this class
  attr_accessor :host, :dns, :dhcp
  attr_reader :dns_ip_missing, :dns_name_missing
  attr_reader :dhcp_entry_missing, :dhcp_entry_broken
  attr_reader :dns_ip_entry_host, :dns_name_entry_host
  attr_reader :dns_ip_secondary_entry_host, :dns_name_secondary_entry_host
  attr_reader :dhcp_mac_entry_host, :dhcp_ip_entry_host

  attr_reader :check, :repairing
  @@attribute_map = {"12" => "name"}

  # It is not good practice to store an ActiveRecord in the session so use our own mini host
  class Host < OpenStruct;   end

  def initialize host, dns, dhcp
    @host  = Host.new host.attributes
    @dns   = dns
    @dhcp  = dhcp
    @check = rand 10000
    @repairing = false
    @dns_ip_missing = @dns_name_missing = @dhcp_entry_missing = @dhcp_entry_broken = false

    # Remove entries where the resource was not found
    @dhcp.keys.each{|k| @dhcp.delete k unless @dhcp[k]}

    # Convert DHCP attribute values into names
    for direction in @dhcp.values
      for key in @@attribute_map.keys
        direction[@@attribute_map[key]] = direction.delete key if direction.has_key? key
      end
    end
  end

  def clearing?
    !repairing
  end

  def dhcp_mac_ip_collision
    dhcp_mac_ip_entry and dhcp_mac_ip_entry != host.ip ? dhcp_mac_ip_entry : false
  end
  def dhcp_mac_ip_entry
    return false unless dhcp[host.mac]
    dhcp[host.mac]["ip"]
  end

  def dhcp_mac_ip_collision_info
    return false unless dhcp[host.mac]
    hostname(host.mac) + " owned by " + dhcp_mac_owner
  end

  def hosts
    [foreman_host(:dhcp, :mac_ip), foreman_host(:dhcp, :ip_mac),
     foreman_host(:dns, :name), foreman_host(:dns, :name_secondary),
     foreman_host(:dns, :ip),   foreman_host(:dns, :ip_secondary)].compact.sort.uniq
  end

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

  def foreman_host db, kind
    db   = db.to_s
    kind = kind.to_s
    return nil unless eval "#{db}_#{kind}_entry"
    inv_kind =(inv db, kind)
    (eval "@#{db}_#{kind}_entry_host ||= ::Host.find_by_#{inv_kind}(#{db}_#{kind}_entry)") || nil
  end

  def owner db, kind
    existing_host = foreman_host db, kind
    existing_host ? existing_host.owner.name : "unknown"
  end

  def hostname ip_or_mac
    hname = dhcp[ip_or_mac].try(:[], "name")
    hname ? hname : "Unnamed host"
  end

  def dhcp_mac_owner; owner :dhcp, :mac_ip; end
  def dhcp_ip_owner;  owner :dhcp, :ip_mac;  end
  def dns_ip_owner;   owner :dns,  :ip;  end
  def dns_name_owner; owner :dns,  :name; end
  def dns_ip_secondary_owner;   owner :dns,  :ip_secondary;  end
  def dns_name_secondary_owner; owner :dns,  :name_secondary; end

  def dhcp_ip_mac_collision
    dhcp_ip_mac_entry and dhcp_ip_mac_entry != host.mac ? dhcp_ip_mac_entry : false
  end
  def dhcp_ip_mac_entry
    return false unless dhcp[host.ip]
    dhcp[host.ip]["mac"]
  end

  def dhcp_ip_mac_collision_info
    return false unless dhcp[host.ip]
    hostname(host.ip) + " owned by " + dhcp_ip_owner
  end

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

  def dns_collisions?
    dns_ip_collision or dns_ip_secondary_collision or dns_name_collision or dns_name_secondary_collision
  end

  def dhcp_collisions?
    dhcp_ip_mac_collision or dhcp_mac_ip_collision
  end

  def empty?
    !dns? and !dhcp?
  end

  def dhcp_same_entry?
    dhcp[host.ip]["name"] == dhcp[host.mac]["name"] and host.ip == dhcp[host.mac]["ip"] and host.mac == dhcp[host.ip]["mac"]
  end

  def no_issues?
    !dhcp_collisions? and !dns_collisions? and !dns_name_missing and !dns_ip_missing and !dhcp_entry_missing and !dhcp_entry_broken
  end

  # This is called on validation so we calculate missing and malformed entries
  def calculate
    @dns_name_missing   = dns[host.name] == false
    @dns_ip_missing     = dns[host.ip]   == false
    @dhcp_entry_missing = dhcp[host.mac] == nil
    @dhcp_entry_broken  = (dhcp[host.mac] and dhcp[host.mac]["ip"] != host.ip)
    @repairing          = true
  end
end
