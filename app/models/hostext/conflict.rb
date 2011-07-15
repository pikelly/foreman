module Hostext::Conflict
  # Resolves network database collisions and omissions
  # This operates in two modes; clearing and repairing.
  # When repairing we add back missing entry and correct wrong ones
  # When clearing we remove ALL entries that we need during the following save operation
  def repair
    unless initialize_dhcp
      errors.add_to_base "Unable to connect to the DHCP server"
      return false
    end
    # We need to get the boot server from this source
    if tftp? and  !initialize_tftp
      errors.add_to_base "Unable to connect to the TFTP server"
      return false
    end
    unless initialize_dns
      errors.add_to_base "Unable to connect to the DNS server"
      return false
    end
    # This code is not executed during a CRUD operation so we can use the default queue
    set_queue

    # Remove the entry at my new target MAC address
    if collision.dhcp_mac_ip_collision
      # Create a host object representing the colliding object so that rollbacks put the modified values back into place
      h = dhcp_clone collision.dhcp
      queue.create(:name => "DHCP Settings for #{h}-#{h.mac}", :priority => 5, :action => [h, :delDHCP])
    end
    # Add my entry if it is missing
    if collision.repairing and collision.dhcp_entry_missing
      queue.create(:name => "DHCP Settings for #{self}-#{self.mac}", :priority => 10, :action => [self, :setDHCP])
    end
    # Remove my current entry if we are clearing
    if collision.clearing? and collision.dhcp_mac_ip_entry
      queue.create(:name => "DHCP Settings for #{self}-#{self.mac}", :priority => 5, :action => [self, :delDHCP])
    end


    #  Remove the PTR record which which we are colliding
    if collision.dns_ip_collision
      h = dns_clone :ip => ip, :name => collision.dns_ip_collision
      queue.create(:name => "Remove Reverse DNS record for #{h}-#{h.ip}", :priority => 1, :action => [h, :delDNSPtr])
    end
    # Remove the A record associated with the previously removed PTR
    if collision.dns_ip_secondary_collision
      h = dns_clone :name => collision.dns_ip_collision, :ip => collision.dns_ip_secondary_collision
      queue.create(:name => "Remove DNS record for #{h}-#{h.name}", :priority => 1, :action => [h, :delDNSRecord])
    end
    # Remove the A record with which we are colliding
    if collision.dns_name_collision
      h = dns_clone :name => name, :ip => collision.dns_name_collision
      queue.create(:name => "Remove DNS record for #{h}-#{h.name}", :priority => 1, :action => [h, :delDNSRecord])
    end
    # Remove the PTR record associated with the previously removed PTR
    if collision.dns_name_secondary_collision
      h = dns_clone :name => collision.dns_name_secondary_collision, :ip => collision.dns_name_collision
      queue.create(:name => "Remove Reverse DNS record for #{h}-#{h.ip}", :priority => 1, :action => [h, :delDNSPtr])
    end

    if collision.repairing
      if collision.dns_name_missing
        queue.create(:name => "DNS record for #{self}-#{self.name}", :priority => 3, :action => [self, :setDNSRecord])
      end
      if collision.dns_ip_missing
        queue.create(:name => "Reverse DNS record for #{self}-#{self.ip}", :priority => 3, :action => [self, :setDNSPtr])
      end
    end

    if collision.clearing?
      if collision.dns_name_entry
        queue.create(:name => "Remove DNS record for #{self}-#{self.name}", :priority => 1, :action => [self, :delDNSRecord])
      end
      if collision.dns_ip_entry
        queue.create(:name => "Remove Reverse DNS record for #{self}-#{self.ip}", :priority => 1, :action => [self, :delDNSPtr])
      end
    end

    process queue rescue ActiveRecord::Rollback   # We are not in a transaction

    errors.empty?
  end

  class NetDBError < StandardError; end

  # Compares the DHCP and DNS values for this host with those in the network databases.
  def collisions validate=nil
    dns_conflicts = dhcp_conflicts = {}
    # Validate the DNS and DHCP entries and accumulate self.errors
    timeout(10){
      raise "Domain information missing" unless dns?
      raise "Subnet information missing" unless dhcp?
      if initialize_dns and dns_conflicts = interrogate_dns and initialize_dhcp and dhcp_conflicts = interrogate_dhcp
        self.collision = Hostext::Collision.new self, dns_conflicts, dhcp_conflicts
      end
    }
    collision.calculate if collision and validate
    collision
  end

  def netdb_conflicts_only?
    !errors.empty? and errors.full_messages.grep(/CONFLICT/) == errors.full_messages
  end
end
