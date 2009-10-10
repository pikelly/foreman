class FactValue < Puppet::Rails::FactValue
  belongs_to :host #ensures we uses our Host model and not Puppets

  # Todo: find a way to filter which values are logged,
  # this generates too much useless data
  #
  # acts_as_audited

  def self.find_empty_facts
    names = Host.first.fact_names{|n| f.name.name}
    for host in Host.all
      for f in names
        puts "#{host.name}:#{f} is empty" if host.fact(f) == nil
      end
    end
    true
  end
end
