module Orchestration
  module DNS
    module Common
      def self.included(base)
        base.class_eval do
          attr_reader :resolver
          attr_accessor :dns
        end
      end

      def dns?
        !domain.nil? and !domain.dns.nil? and !domain.dns.url.empty?
      end

      def initialize_dns
        return unless dns?
        @dns ||= ProxyAPI::DNS.new(:url => domain.dns.url)
        @resolver ||= Resolv::DNS.new :search => domain.name, :nameserver => domain.nameservers, :ndots => 1
        @dns and @resolver
      rescue StandardError, Timeout::Error=> e
        failure "Failed to initialize the DNS proxy: #{e}"
      end

      def interrogate_dns
        collisions = {}
        fname = "#{name}#{"." + domain.name if domain and name !~ /\./}"
        address = dns_find(fname)
        collisions[:dns_name_entry] = OpenStruct.new :ip => address, :name => address.nil? ? nil :fname
        if address and hostname = dns_find(address)
          collisions[:dns_name_secondary_entry] = OpenStruct.new :name => hostname, :ip => address
        else
          collisions[:dns_name_secondary_entry] = OpenStruct.new :name => nil, :ip => nil
        end
        hostname = dns_find(ip)
        collisions[:dns_ip_entry] = OpenStruct.new :name => hostname, :ip => hostname.nil? ? nil : ip
        if hostname and address = dns_find(hostname)
          collisions[:dns_ip_secondary_entry] = OpenStruct.new :ip => address, :name => hostname
        else
          collisions[:dns_ip_secondary_entry] = OpenStruct.new :ip => nil, :name => nil
        end
        collisions
      rescue => e
        failure "Failed to query DNS: #{e}"
      end

      # Adds the host to the forward DNS zone
      # +returns+ : Boolean true on success
      def setDNSRecord
        logger.info "{#{User.current.login}}Add the DNS record for #{name}/#{ip}"
        dns.set(:fqdn => name, :value => ip, :type => "A")
      rescue => e
        failure "Failed to create the DNS record: #{proxy_error e}"
      end

      # Adds the host to the reverse DNS zone
      # +returns+ : Boolean true on success
      def setDNSPtr
        logger.info "{#{User.current.login}}Add the Reverse DNS records for #{name}/#{to_arpa ip}"
        dns.set(:fqdn => name, :value => to_arpa(ip), :type => "PTR")
      rescue => e
        failure "Failed to create the Reverse DNS record: #{proxy_error e}"
      end

      # Removes the host from the forward DNS zones
      # +returns+ : Boolean true on success
      def delDNSRecord hostname=name
        logger.info "{#{User.current.login}}Delete the DNS record for #{hostname}"
        dns.delete(hostname)
      rescue => e
        failure "Failed to delete the DNS record: #{proxy_error e}"
      end

      # Removes the host from the forward DNS zones
      # +returns+ : Boolean true on success
      def delDNSPtr address=ip
        logger.info "{#{User.current.login}}Delete the DNS reverse record for #{to_arpa address}"
        dns.delete(to_arpa address)
      rescue => e
        failure "Failed to delete the reverse DNS record: #{proxy_error e}"
      end

      def queue_dns_create_a
        queue.create(:name => "DNS record for #{self}", :priority => 3,
                     :action => [self, :setDNSRecord])
      end

      def queue_dns_create_ptr
        queue.create(:name => "Reverse DNS record for #{self}", :priority => 3,
                     :action => [self, :setDNSPtr])
      end

      private

      def queue_dns_create
        queue_dns_create_a
        queue_dns_create_ptr
      end

      def queue_dns_destroy
        return unless dns? and errors.empty?
        queue_dns_destroy_a
        queue_dns_destroy_ptr
      end

      def queue_dns_destroy_a
        queue.create(:name => "Remove DNS record for #{self}", :priority => 1,
                     :action => [self, :delDNSRecord])
      end

      def queue_dns_destroy_ptr
        queue.create(:name => "Remove Reverse DNS record for #{self}", :priority => 1,
                     :action => [self, :delDNSPtr])
      end
      # Returns: String containing the ip in the in-addr.arpa zone
      def to_arpa address
        address.split(/\./).reverse.join(".") + ".in-addr.arpa"
      end

      # Looks up the IP or MAC address. Handles the conversion of a DNS miss
      # exception into false
      # [+ip_or_name+]: IP or hostname
      # Returns: String containing the IP or Hostname OR false if there is no entry
      def dns_find ip_or_name
        if ip_or_name =~ /\d{1,3}(\.\d{1,3}){3}/
          resolver.getname(ip_or_name).to_s
        else
          resolver.getaddress(ip_or_name).to_s
        end
      rescue Resolv::ResolvError
        nil
      end
    end
  end
end
