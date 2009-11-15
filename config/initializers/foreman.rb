require 'puppet'
require 'gchart'

# import settings file
$settings = YAML.load_file("#{RAILS_ROOT}/config/settings.yaml")

Puppet[:config] = $settings[:puppetconfdir] || "/etc/puppet/puppet.conf"
Puppet.parse_config

# Add an empty method to nil. Now no need for if x and x.empty?. Just x.empty?
class NilClass
  def empty?
    true
  end
end

class ActiveRecord::Base

  def update_single_attribute(attribute, value)
    connection.update(
      "UPDATE #{self.class.table_name} " +
      "SET #{attribute.to_s} = #{value} " +
      "WHERE #{self.class.primary_key} = #{id}",
      "#{self.class.name} Attribute Update"
    )
  end
  private
  def ensure_not_used
    puts "Count is #{hosts.count}"
    puts to_s
    hosts.each do |host|
      self.errors.add_to_base(to_label + " is used by " + host.hostname)
    end
    puts "good"
    unless errors.empty?
      logger.error "You may not destroy #{to_label} as it is in use!"
      #raise ApplicationController::InvalidDeleteError.new, errors.full_messages.join("<br>")
      puts "BAD"
      false
    else
      true
    end
  end
end

module ExemptedFromLogging
  def process(request, *args)
    logger.silence { super }
  end
end
