module Orchestration::DHCP
  def self.included(base)
    base.send :include, InstanceMethods
    base.class_eval do
      attr_reader :dhcp
      after_validation  :initialize_dhcp, :queue_dhcp
      before_destroy    :initialize_dhcp, :queue_dhcp_destroy
      validate :ip_belongs_to_subnet?
    end
  end

  module InstanceMethods

    def dhcp?
      !subnet.nil? and !subnet.dhcp.nil? and !subnet.dhcp.url.empty?
    end

    protected

    def initialize_dhcp sub = nil
      return unless dhcp?
      # there are usage cases where our object is saved across subnets
      # i.e. management port is not on the same subnet
      sub ||= subnet
      @dhcp = ProxyAPI::DHCP.new(:url => sub.dhcp.url)
      @resolver ||= Resolv::DNS.new :search => domain.name, :nameserver => domain.nameservers, :ndots => 1
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
      logger.info "Query a DHCP reservation for #{name}/#{ip}"
      dhcp.record subnet.network, mac
    rescue => e
      failure "Failed to read the DHCP record: #{proxy_error e}"
    end

    # Deletes the DHCP entry for this host
    def delDHCP
      logger.info "{#{User.current.login}}Delete the DHCP reservation for #{name}/#{ip}"
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
      dhcp_attr = {:name => name, :filename => operatingsystem.boot_filename(self),
                   :ip => ip, :nextserver => boot_server, :mac => mac, :hostname => name}

      dhcp_attr.merge! @jumpstart_params if jumpstart? and !(@jumpstart_params = jumpstart_params).empty?

      dhcp.set subnet.network, dhcp_attr
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
      failure "failed to detect boot server: #{e}"
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
      # Jumpstart builds are much more sensitive to host attribute changes
      if jumpstart? and update == false # No point in doing this if we are already scheduled to delete
        if (current = dhcp.record subnet.network, mac)
          jpath       = operatingsystem.jumpstart_path medium, domain
          ipath       = operatingsystem.interpolate_medium_vars(medium.media_dir, architecture.name, operatingsystem)
          # The vendor class may be a gini-compatible abbreviated vendor name
          actual_vendor = current.keys.find{|k| k =~ /^</}.match(/^<([^>]+)>/)[1] rescue model.vendor_class
          if current["<#{actual_vendor}>14"].nil? or current["<#{actual_vendor}>14"] != jpath or
             current["<#{actual_vendor}>4"].nil?  or current["<#{actual_vendor}>4"]  !~ /#{ipath}/   or
             current["<#{actual_vendor}>3"].nil?  or current["<#{actual_vendor}>3"]  != medium.media_host
            old.initialize_dhcp if old.dhcp.nil? and old.dhcp?
            queue.create(:name => "DHCP Settings for #{old}", :priority => 5,
                       :action => [old, :delDHCP])
            update = true
          end
        else
          # We could not find a DHCP entry so create one
          update = true
        end
      end
      queue_dhcp_create if update
    end

    def queue_dhcp_destroy
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

    def jumpstart_params
      # root server and install server are always the same under Foreman
      server_name = medium.media_host
      server_ip   = @resolver.getaddress(server_name).to_s
      jpath       = operatingsystem.jumpstart_path medium, domain
      ipath       = operatingsystem.interpolate_medium_vars(medium.media_dir, architecture.name, operatingsystem)

      return failure "Host's operating system has an unknown vendor class" unless (vendor = model.vendor_class)

      {
      "<#{vendor}>root_server_ip"        => server_ip,                                                # 172.29.216.241
      "<#{vendor}>root_server_hostname"  => server_name,                                              # s02
      "<#{vendor}>root_path_name"        => "#{ipath}/Solaris_#{operatingsystem.minor}/Tools/Boot", # /vol/s02/solgi_5.10/sol10_hw0910/Solaris_10/Tools/Boot
      "<#{vendor}>install_server_ip"     => server_ip,                                                # 172.29.216.241
      "<#{vendor}>install_server_name"   => server_name,                                              # s02
      "<#{vendor}>install_path"          => ipath,                                                  # /vol/s02/solgi_5.10/sol10_hw0910
      "<#{vendor}>sysid_server_path"     => "#{jpath}/sysidcfg/sysidcfg_primary",                     # 172.29.216.241:/vol/s02/jumpstart/sysidcfg/sysidcfg_primary
      "<#{vendor}>jumpstart_server_path" => jpath,                                                    # 172.29.216.241:/vol/s02/jumpstart
      }
    end
  end
end
