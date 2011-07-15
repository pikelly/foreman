module Orchestration::DHCP
  def self.included(base)
    base.send :include, InstanceMethods
    base.class_eval do
      attr_accessor :dhcp
      after_validation  :initialize_dhcp, :queue_dhcp
      before_destroy    :initialize_dhcp, :queue_dhcp_destory
      validate :ip_belongs_to_subnet?
    end
  end

  module InstanceMethods

    def dhcp?
      !subnet.nil? and !subnet.dhcp.nil? and !subnet.dhcp.url.empty?
    end

    protected

    def initialize_dhcp sub = nil
      return false unless dhcp?
      # there are usage cases where our object is saved across subnets
      # i.e. management port is not on the same subnet
      sub ||= subnet
      @dhcp = ProxyAPI::DHCP.new(:url => sub.dhcp.url)
    rescue => e
      failure "Failed to initialize the DHCP proxy: #{e}"
    end

    # Retrieves the DHCP entry for this host via a lookup on the MAC
    # Returns: Hash  Example {
    #   "mac"       :"22:33:44:55:66:11"
    #   "nextServer":"192.168.122.1"
    #   "title"     :"some.host.name"
    #   "filename"  :"pxelinux.0"
    #   "ip"        :"192.168.122.4"}
    def getDHCP
      logger.info "Query a DHCP reservation for #{name}/#{mac}"
      dhcp.record subnet.network, mac
    rescue => e
      failure "Failed to read the DHCP record: #{proxy_error e}"
    end

    # Deletes the DHCP entry for this host
    def delDHCP
      logger.info "{#{User.current.login}}Delete the DHCP reservation for #{name}/#{mac}"
      dhcp.delete subnet.network, mac
    rescue => e
      failure "Failed to delete the DHCP record: #{proxy_error e}"
    end

    def delSPDHCP
      return true unless sp_valid?
      initialize_dhcp(sp_subnet) unless subnet == sp_subnet
      logger.info "{#{User.current.login}}Delete a DHCP reservation for #{sp_name}/#{sp_ip}"
      dhcp.delete subnet.network, sp_mac
    rescue => e
      failure "Failed to delete the Service Processor DHCP record: #{proxy_error e}"
    end

    # Updates the DHCP scope to add a reservation for this host
    # +returns+ : Boolean true on success
    def setDHCP
      logger.info "{#{User.current.login}}Add a DHCP reservation for #{name}/#{ip}"
      dhcp.set subnet.network,({:name => name, :filename => operatingsystem.boot_filename,
                               :ip => ip, :nextserver => boot_server, :mac => mac})
    rescue => e
      failure "Failed to set the DHCP record: #{proxy_error e}"
    end

    def setSPDHCP
      return true unless sp_valid?
      initialize_dhcp(sp_subnet) unless subnet == sp_subnet
      logger.info "{#{User.current.login}}Add a DHCP reservation for #{sp_name}/#{sp_ip}"
      dhcp.set sp_subnet.network, sp_mac, :name => sp_name, :ip => sp_ip
    rescue => e
      failure "Failed to set the Service Processor DHCP record: #{proxy_error e}"
    end

    def interrogate_dhcp
      options = getDHCP
      options ? options : {}
    rescue => e
      failure "Failed to query the DHCP: #{e}"
    end

    private

    # where are we booting from
    def boot_server

      # if we don't manage tftp at all, we dont create a next-server entry.
      return nil if tftp.nil?

      begin
        bs = tftp.bootServer
      rescue RestClient::ResourceNotFound
        nil
      end
      if bs.blank?
        # trying to guess out tftp next server based on the smart proxy hostname
        bs = URI.parse(subnet.tftp.url).host if subnet and subnet.tftp and subnet.tftp.url
      end
      return bs unless bs.blank?
      failure "Unable to determine the host's boot server. The DHCP smart proxy failed to provide this information and this subnet is not provided with TFTP services."
    rescue => e
      failure "Failed to retrieve boot server from TFTP server: #{e}"
      raise
    end

    def queue_dhcp
      return unless dhcp? and errors.empty?
      new_record? ? queue_dhcp_create : queue_dhcp_update
    end

    def queue_dhcp_create
      queue.create(:name => "DHCP Settings for #{self}", :priority => 10,
                   :action => [self, :setDHCP])
      queue.create(:name => "DHCP Settings for #{sp_name}", :priority => 15,
                   :action => [self, :setSPDHCP]) if sp_valid?
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
      queue_dhcp_create if update
    end

    def queue_dhcp_destory
      return unless dhcp? and errors.empty?
      queue.create(:name => "DHCP Settings for #{self}", :priority => 5,
                   :action => [self, :delDHCP])
      queue.create(:name => "DHCP Settings for #{sp_name}", :priority => 5,
                   :action => [self, :delSPDHCP]) if sp_valid?
      true
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

    def dhcp_clone options
      h = self.clone
      h.dhcp = dhcp
      for key, value in options
        h.send "#{key}=",  value
      end
      # We do not save!
      h
    end

  end
end
