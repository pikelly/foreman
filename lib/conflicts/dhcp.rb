class Conflicts::Dhcp < Conflict
  include Orchestration::DHCP::Common
  attr_accessor :dhcp_attr, :owner, :subnet_id, :errors, :name, :mac

  def self.find host
    Conflicts::Dhcp.new(host, {}, :dhcp_mac_entry).find host
  end

  # Return a trimmed conflicts list by removing conflicting or missing entries
  # depending on whether we are clearing or regenerating the Host or ConflictList
  def self.cleanup conflicts, mode
    result = []
    for conflict in conflicts
      next unless conflict.instance_of?(Conflicts::Dhcp)
      next if (result.find{|c| c.instance_of?(Conflicts::Dhcp) and conflict.mac == c.mac and conflict.ip == c.ip})
      next if (mode == :clear and conflict.dhcp_attr.empty?)
      next if (mode == :regenerate and !conflict.missing?)
      result << conflict
    end
    result
  end

  def find host
    raise "Unable to initialize DHCP" unless initialize_dhcp
    [Conflicts::Dhcp.new(host, interrogate_dhcp(host.mac), :dhcp_mac_entry),
     Conflicts::Dhcp.new(host, interrogate_dhcp(host.ip),  :dhcp_ip_entry)]
  end

  def initialize host, data, kind
    self.name, self.mac, self.ip = host.name, data["mac"], data["ip"]
    self.kind           = kind
    self.dhcp_attr      = data
    self.subnet_id      = host.subnet_id
    @conflicting        = (ip and ip != host.ip or mac and mac != host.mac)
    @missing            = (data.empty? or conflicting?)
    self.colliding_host = ((mac and Host.find_by_mac(mac)) or (ip and Host.find_by_ip(ip)))
    self.owner          = colliding_host ? colliding_host.owner.name : "unknown" rescue "unknown"
    self.colliding_host = self.colliding_host.try :name
    self.errors         = ActiveResource::Errors.new(self)
  end

  def method_missing method_id
    dhcp_attr[method_id.to_s]
  end

  # To clear we remove the entry whether it conflicts or not
  # The create operation following this action will add the required DHCP record
  def clear queue
    unless initialize_dhcp
      errors.add_to_base "Unable to connect to the DHCP server"
      return false
    end
    # We need to get the boot server from this source
    if tftp? and  !initialize_tftp
      errors.add_to_base "Unable to connect to the TFTP server"
      return false
    end
    self.queue = queue
    queue_dhcp_destroy
  end

  def regenerate host
    host.queue_dhcp_create if missing?
  end

  private
  def subnet
    Subnet.find subnet_id
  end
end
