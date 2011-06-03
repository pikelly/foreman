class Conflicts::Dns < Conflict
  include Orchestration::DNS::Common
  attr_accessor :name, :owner, :errors, :domain_id

  def initialize host, name, ip, kind
    self.name, self.ip, self.kind  = name, ip, kind
    self.host           = OpenStruct.new :mac => host.attributes["mac"], :ip => host.attributes["ip"], :name => host.attributes["name"]
    self.owner          = self.colliding_host ? self.colliding_host.owner.name : "unknown" rescue "unknown"
    self.colliding_host = colliding_host.name if colliding_host
    self.errors         = ActiveResource::Errors.new(self)
    self.domain_id      = host.domain.id
    @conflicting        = ((name and (name != host.name)) or (ip and (ip != host.ip)))
    @missing            = (name.empty? and ip.empty? or conflicting?)
  end

  def self.find host
    Conflicts::Dns.new(host, host.name, host.ip, :dns_ip_entry).find host
  end

  # Return a trimmed conflicts list by removing duplicate, conflicting or missing entries
  # depending on whether we are clearing or regenerating the Host or ConflictList
  def self.cleanup conflicts,  mode
    result = []
    for conflict in conflicts
      next unless conflict.kind_of? Conflicts::Dns
      next if result.find{|c| c.name == conflict.name and c.ip == conflict.ip and c.class == conflict.class}
      next if (mode == :clear and name.empty? and ip.empty?)
      next if (mode == :regenerate and conflict.kind.to_s =~ /secondary/)
      next if (mode == :regenerate and !conflict.missing?)

      result << conflict
    end
    result
  end

  def find host
    raise "Unable to initialize DNS" unless initialize_dns
    conflicts = []
    for kind, mapping in interrogate_dns
      if kind == :dns_ip_entry or kind == :dns_name_secondary_entry
        (conflicts << Conflicts::DnsPtr.new(host, mapping.name, mapping.ip, kind))
      else
        (conflicts << Conflicts::DnsA.new(host, mapping.name, mapping.ip, kind))
      end
    end
    conflicts
  end

  def clear queue
    unless initialize_dns
      errors.add_to_base "Unable to connect to the DNS server"
      return false
    end
    self.queue = queue
  end

  def domain
    Domain.find domain_id
  end
end

class Conflicts::DnsA < Conflicts::Dns
  def initialize host, name, ip, kind
    self.colliding_host = Host.find_by_name name if name
    super
  end

  # To clear we just remove the entry whether it conflicts or not
  # The create operation following this action will add the required DNS records
  def clear queue
    return false unless super
    queue_dns_destroy_a if ip
  end

  def regenerate host
    host.queue_dns_create_a if missing? and kind.to_s !~ /secondary/
  end
end

class Conflicts::DnsPtr < Conflicts::Dns
  def initialize host, name, ip, kind
    self.colliding_host = Host.find_by_ip ip if ip
    super
  end

  # To clear we just remove all entries whether they conflict or not
  # The create operation following this action will add the required DNS records
  def clear queue
    return false unless super
    queue_dns_destroy_ptr if name
  end

  def regenerate host
    host.queue_dns_create_ptr if missing? and kind !~ /secondary/
  end

end
