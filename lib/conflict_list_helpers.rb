module ConflictListHelpers
  def dns_name_missing
    conflicts.each{|c| return false if c.is_a?(Conflicts::DnsA) and c.name == host.name and c.ip == host.ip}
    return true
  end

  def dns_ip_missing
    conflicts.each{|c| return false if c.is_a?(Conflicts::DnsPtr) and c.ip == host.ip and c.name == host.name}
    return true
  end

  def no_issues?
    conflicts.map{|c| c.conflicting? }.uniq.flatten == [false] and !dns_name_missing and !dns_ip_missing and !dhcp_entry_missing
  end

  def none_conflicting
    conflicts.each{|c| return false if c.conflicting?}
    true
  end

  def hosts
    conflicts.map{|c| c.colliding_host}.compact.uniq
  end

  def dns_collisions?
    conflicts.each{|c| return true if c.is_a? Conflicts::Dns and c.ip and c.name}
    false
  end

  def dns_ip
    conflicts.find{|c| c.is_a? Conflicts::DnsPtr and c.kind == :dns_ip_entry}
  end
  def dns_ip_entry
    dns_ip.try :name
  end
  def dns_ip_collision
    dns_ip && dns_ip.conflicting? ? dns_ip.try(:name) : nil
  end
  def dns_ip_owner; dns_ip.try :owner; end

  def dns_name
    conflicts.find{|c| c.is_a? Conflicts::DnsA and c.kind == :dns_name_entry}
  end
  def dns_name_entry
    dns_name.try :ip
  end
  def dns_name_collision
    dns_name && dns_name.conflicting? ? dns_name.try(:ip)  : nil
  end
  def dns_name_owner; dns_name.try :owner; end

  def dns_ip_secondary
    conflicts.find{|c| c.is_a? Conflicts::DnsA and c.kind == :dns_ip_secondary_entry}
  end
  def dns_ip_secondary_entry
    dns_ip_secondary.try :ip
  end
  def dns_ip_secondary_collision
    dns_ip_secondary && dns_ip_secondary.conflicting? ? dns_ip_secondary.try(:ip) : nil
  end
  def dns_ip_secondary_owner; dns_name.try :owner; end

  def dns_name_secondary
    conflicts.find{|c| c.is_a? Conflicts::DnsPtr and c.kind == :dns_name_secondary_entry}
  end
  def dns_name_secondary_entry
    dns_name_secondary.try :name
  end
  def dns_name_secondary_collision
    dns_name_secondary && dns_name_secondary.conflicting? ? dns_name_secondary.try(:name) : nil
  end
  def dns_name_secondary_owner; dns_name_secondary.try :owner; end

  def dhcp_entry_missing
    conflicts.each{|c| return false if c.is_a?(Conflicts::Dhcp) and c.mac == host.mac and c.ip == host.ip}
    return true
  end

  def dhcp_collisions?
    conflicts.each{|c| return true if c.is_a? Conflicts::Dhcp and c.conflicting?}
    false
  end

  def dhcp_mac_ip
    conflicts.find{|c| c.is_a? Conflicts::Dhcp and c.kind == :dhcp_mac_entry}
  end
  def dhcp_mac_ip_entry
    dhcp_mac_ip.try :ip
  end
  def dhcp_mac_ip_collision_info
    return false unless dhcp_mac_ip.mac
    dhcp_mac_ip.mac + " owned by " + (dhcp_mac_ip.owner || "unknown")
  end

  def dhcp_ip_mac
    conflicts.find{|c| c.is_a? Conflicts::Dhcp and c.kind == :dhcp_ip_entry}
  end
  def dhcp_ip_mac_entry
    dhcp_ip_mac.try :mac
  end
  def dhcp_ip_mac_collision_info
    return false unless dhcp_ip_mac.ip
    dhcp_ip_mac.ip + " owned by " + (dhcp_ip_mac.owner || "unknown")
  end


end
