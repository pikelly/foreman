require 'resolv'
require "timeout"

module Orchestration::DNS
  def self.included(base)
    base.send :include, InstanceMethods
    base.class_eval do
      attr_reader :dns, :resolver
      after_validation :initialize_dns, :validate_dns, :queue_dns
      before_destroy   :initialize_dns, :queue_dns_destroy
    end
  end

  module InstanceMethods

    def dns?
      !domain.nil? and !domain.dns.nil? and !domain.dns.url.empty?
    end

    protected

    def initialize_dns
      return false unless dns?
      @dns      ||= ProxyAPI::DNS.new(:url => domain.dns.url )
      @resolver ||= Resolv::DNS.new :search => domain.name, :nameserver => domain.nameservers, :ndots => 1
      @dns and @resolver
    rescue StandardError, Timeout::Error=> e
      failure "Failed to initialize the DNS proxy: #{e}"
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

    private

    # Returns: String containing the ip in the in-addr.arpa zone
    def to_arpa address
      address.split(/\./).reverse.join(".") + ".in-addr.arpa"
    end

    def validate_dns
      return unless dns?
      return if Rails.env == "test"
      #return true # DEBUGDEBUGDEBUG
      # limit DNS validations to 3 seconds
      Timeout::timeout(3) do
        new_record? ? validate_dns_on_create : validate_dns_on_update
      end
    rescue Timeout::Error => e
      failure "Timeout querying DNS: #{e}"
    end

    def dns_find key
      if key =~ /\d{1,3}(\.\d{1,3}){3}/
        resolver.getname(key).to_s
      else
        resolver.getaddress(key).to_s
      end
    rescue Resolv::ResolvError
      false
    end

    def interrogate_dns
      collisions = {}
      fname = "#{name}#{"." + domain.name if domain and name !~ /\./}"
      address = dns_find(fname)
      collisions[fname] = address
      if address and hostname = dns_find(address)
        collisions[address] = hostname
      end
      hostname = dns_find(ip)
      collisions[ip] = hostname
      if hostname and address = dns_find(hostname)
        collisions[hostname] = address
      end
      collisions
    rescue => e
      failure "Failed to query DNS: #{e}"
    end

    def validate_dns_on_create
      if address = dns_find(name)
        failure "#{name} is already in DNS with an address of #{address}"
      end
      if hostname = dns_find(ip)
        failure "#{ip} is already in the DNS with a name of #{hostname}"
      end
    rescue => e
      failure "Failed to query DNS: #{e}"
    end

    def validate_dns_on_update
      if address = dns_find(name)
        failure "#{name} DNS record ip #{address} does not match #{ip}" unless address == ip
      end
      if hostname = dns_find(ip)
        failure "#{ip} PTR record is #{hostname} expecting #{name}" unless hostname == name
      end
    rescue => e
      failure "Failed to query DNS: #{e}"
    end

    def queue_dns
      return unless dns? and errors.empty?
      new_record? ? queue_dns_create : queue_dns_update
    end

    def queue_dns_create
      queue.create(:name => "DNS record for #{self}", :priority => 3,
                   :action => [self, :setDNSRecord])
      queue.create(:name => "Reverse DNS record for #{self}", :priority => 3,
                   :action => [self, :setDNSPtr])
    end

    def queue_dns_update
      if old.ip != ip or old.name != name
        if old.dns?
          old.initialize_dns
          queue.create(:name => "Remove DNS record for #{old}", :priority => 1,
                       :action => [old, :delDNSRecord])
          queue.create(:name => "Remove Reverse DNS record for #{old}", :priority => 1,
                       :action => [old, :delDNSPtr])
        end
        queue_dns_create
      end
    end

    def queue_dns_destroy
      return unless dns? and errors.empty?
      queue.create(:name => "Remove DNS record for #{self}", :priority => 1,
                   :action => [self, :delDNSRecord])
      queue.create(:name => "Remove Reverse DNS record for #{self}", :priority => 1,
                   :action => [self, :delDNSPtr])
    end

  end

end
