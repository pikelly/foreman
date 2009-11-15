class Puppetclass < ActiveRecord::Base
  has_many                :muxes
  has_and_belongs_to_many :hostgroups
  has_and_belongs_to_many :direct_hosts, :class_name => "Host", :join_table => "hosts_puppetclasses", 
                          :association_foreign_key => "host_id", :foreign_key => "puppetclass_id"

  has_and_belongs_to_many :environments
  
  has_many :valid_operatingsystems, :through => :muxes, :uniq => true, :source => :operatingsystem
  has_many :valid_architectures,    :through => :muxes, :uniq => true, :source => :architecture
  
  validates_uniqueness_of :name
  validates_presence_of   :name
  validates_associated    :environments

  def indirect_hosts
    hostgroups.map {|hg| hg.hosts}.flatten.uniq
  end
  def hosts
    (direct_hosts + indirect_hosts).uniq  
  end
  # scans for puppet classes
  # parameter is the module path
  # returns an array of puppetclasses objects
  def self.scanForClasses(path)
    klasses=Array.new
    Dir.glob("#{path}/*/manifests/*.pp").each do |manifest|
      File.read(manifest).each_line do |line|
        klass=line.match(/^class (\S+).*\{/)
         klasses << Puppetclass.find_or_create_by_name(klass[1]) if klass
      end
    end
    return klasses
  end

  def to_s
    name
  end
  
  def self.build_from_facts host
    if host.name=~/...[ul]c/
       Puppetclass.find_or_create_by_name("host-rd-compute")
    else
       Puppetclass.find_or_create_by_name("host-base")
    end
  end
end
