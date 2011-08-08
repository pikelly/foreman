# A conflict list is generated when a compare(repair) is performed, or a create/update fails.
# It represents a comparison of the host's attributes and the contents of the DNS and DHCP network databases.
# When a repair operation has been requested then we know that the host already exists and should have all
# netdb entries present.
#
# DNS Collisions and Omissions
# A host's name is in collision if we can resolv name
# A host's ip   is in collision if we can resolv ip
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

class ConflictList
  include Orchestration::Common
  attr_accessor :conflicts, :host, :check, :queue, :errors

  def initialize host
    attr           = host.attributes
    self.host      = OpenStruct.new host.attributes
    self.check     = rand 10000
    self.conflicts = []
    self.errors    = ActiveResource::Errors.new(self)
    self.class.conflict_sources.each{|s| self.conflicts += s.find(host)}
  end

  def clear
    set_queue

    cleanup(:clear).each{|c| c.clear queue}
    return false unless conflict_errors.empty?

    run_queue
  end

  # Accumulate all base error messages and return in an ActiveResource::Errors object
  def conflict_errors
    result = ActiveResource::Errors.new(self)
    for conf in conflicts
      for msg in conf.errors[:base]
        result.add_to_base msg
      end if conf.errors[:base]
    end
    result
  end

  def cleanup mode
    cleaned_conflicts = []
    for source in self.class.conflict_sources
      cleaned_conflicts += source.cleanup conflicts, mode
    end
    cleaned_conflicts
  end

  include ConflictListHelpers
  private

end
