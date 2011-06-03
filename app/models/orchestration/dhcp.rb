module Orchestration::DHCP
  def self.included(base)
    base.send :include, InstanceMethods
    base.class_eval do
      after_validation  :initialize_dhcp, :queue_dhcp
      before_destroy    :initialize_dhcp, :queue_dhcp_destroy
      validate :ip_belongs_to_subnet?
    end
  end

  module InstanceMethods
    include Orchestration::DHCP::Common

    protected

    private

    def queue_dhcp
      return unless dhcp? and errors.empty?
      new_record? ? queue_dhcp_create : queue_dhcp_update
    end


    def queue_dhcp_update
      update = false
      # IP Address  / name changed
      if (old.ip != ip) or (old.name != name) or (old.mac != mac)
        update = true
        if old.dhcp?
          old.initialize_dhcp
          queue.create(:name => "DHCP Settings for #{old}", :priority => 5,
                       :action => [old, :delDHCP])
        end
      end
      if old.sp_valid? and ((old.sp_name != sp_name) or (old.sp_mac != sp_mac) or (old.sp_ip != sp_ip))
        update = true
        if old.sp_subnet and old.sp_subnet.dhcp and old.sp_subnet.dhcp.url
          queue.create(:name => "DHCP Settings for #{old.sp_name}", :priority => 5,
                       :action => [old, :delSPDHCP])
        end
      end
      # Handle jumpstart
      if jumpstart?
        if !old.build? or (old.medium != medium or old.arch != arch) or
                          (os and old.os and (old.os.name != os.name or old.os != os))
          update = true
          old.initialize_dhcp if old.dhcp.nil? and old.dhcp?
          queue.create(:name => "DHCP Settings for #{old}", :priority => 5, :action => [old, :delDHCP])
        end
      end
      queue_dhcp_create if update
    end

    def ip_belongs_to_subnet?
      return if subnet.nil? or ip.nil?
      return unless dhcp?
      unless subnet.contains? ip
        errors.add :ip, "Does not match selected Subnet"
        return false
      end
    rescue => e
      # probably an invalid ip / subnet were entered
      # we let other validations handle that
    end

  end
end
