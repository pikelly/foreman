require 'resolv'
require "timeout"

module Orchestration::DNS
  def self.included(base)
    base.send :include, InstanceMethods
    base.class_eval do
      after_validation :initialize_dns, :validate_dns, :queue_dns
      before_destroy   :initialize_dns, :queue_dns_destroy
    end
  end

  module InstanceMethods

    include Orchestration::DNS::Common
    protected

    private


    def validate_dns
      return unless dns?
      return if Rails.env == "test"
      # limit DNS validations to 3 seconds
      Timeout::timeout(3) do
        new_record? ? validate_dns_on_create : validate_dns_on_update
      end
    rescue Timeout::Error => e
      failure "Timeout querying DNS: #{e}"
    end

    def validate_dns_on_create
      if address = dns_find(name)
        failure "CONFLICT:#{name} is already in DNS with an address of #{address}"
      end
      if hostname = dns_find(ip)
        failure "CONFLICT:#{ip} is already in the DNS with a name of #{hostname}"
      end
    rescue => e
      failure "Failed to query DNS: #{e}"
    end

    def validate_dns_on_update
      target_name = changes[:name].empty? ? name : changes[:name][1]
      target_ip   = changes[:ip].empty?   ? ip   : changes[:ip][1]
      if address = dns_find(target_name)
        failure "CONFLICT:#{target_name} DNS record ip #{address} does not match #{target_ip}" unless address == target_ip
      end
      target = changes[:ip].empty? ? ip : changes[:ip][1]
      if hostname = dns_find(target)
        failure "CONFLICT:#{target} PTR record is #{hostname} but was expecting #{name}" unless hostname == target_name
      end
    rescue => e
      failure "Failed to query DNS: #{e}"
    end

    def queue_dns
      return unless dns? and errors.empty?
      new_record? ? queue_dns_create : queue_dns_update
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


  end

end
