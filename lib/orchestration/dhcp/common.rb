module Orchestration
  module DHCP
    module Common
      def self.included(base)
        base.class_eval do
          attr_accessor :dhcp, :tftp
        end
      end

      def dhcp?
        !subnet.nil? and !subnet.dhcp.nil? and !subnet.dhcp.url.empty?
      end

      def initialize_dhcp sub = nil
        return false unless dhcp?
        # there are usage cases where our object is saved across subnets
        # i.e. management port is not on the same subnet
        sub ||= subnet
        @dhcp = ProxyAPI::DHCP.new(:url => sub.dhcp.url)
      rescue => e
        failure "Failed to initialize the DHCP proxy: #{e}"
      end

      def interrogate_dhcp key
        options = getDHCP key
        options ? options : {}
      rescue => e
        failure "Failed to query the DHCP: #{e}"
      end

      def dhcp_attr
        attr = {:name => name, :filename => operatingsystem.boot_filename(self),
                :ip => ip, :mac => mac, :hostname => name}

        next_server = boot_server
        attr.merge!(:nextserver => next_server) if next_server

        if jumpstart?
          raise "Host's operating system has an unknown vendor class" unless (vendor = model.vendor_class and !vendor.empty?)

          jumpstart_arguments = os.jumpstart_params self, vendor
          attr.merge! jumpstart_arguments unless jumpstart_arguments.empty?
        end
        attr
      end


      protected

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

      # Retrieves the DHCP entry for this host via a lookup on the MAC
      # Returns: Hash  Example {
      #   "mac"       :"22:33:44:55:66:11"
      #   "nextServer":"192.168.122.1"
      #   "title"     :"some.host.name"
      #   "filename"  :"pxelinux.0"
      #   "ip"        :"192.168.122.4"}
      def getDHCP key
        logger.info "Query a DHCP reservation for #{name}/#{mac}"
        dhcp.record subnet.network, key
      rescue => e
        failure "Failed to read the DHCP record: #{proxy_error e}"
      end

      def queue_dhcp_create
        queue.create(:name => "DHCP Settings for #{self}", :priority => 10,
                     :action => [self, :setDHCP])
        queue.create(:name => "DHCP Settings for #{sp_name}", :priority => 15,
                     :action => [self, :setSPDHCP]) if sp_valid?
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

      def queue_dhcp_destroy
        return unless dhcp? and errors.empty?
        queue.create(:name => "DHCP Settings for #{self}", :priority => 5,
                     :action => [self, :delDHCP])
        queue.create(:name => "DHCP Settings for #{sp_name}", :priority => 5,
                     :action => [self, :delSPDHCP]) if sp_valid?
        true
      end
    end
  end
end
