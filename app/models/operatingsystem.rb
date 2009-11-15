class Operatingsystem < ActiveRecord::Base
  has_many :muxes
  has_many :hosts

  has_many :medias
  has_and_belongs_to_many :ptables
  
  has_many :valid_architectures, :through => :muxes, :uniq => true, :source => :architecture
  has_many :valid_puppetclasses, :through => :muxes, :uniq => true, :source => :puppetclass
  has_many :architectures,       :through => :hosts, :uniq => true
  
  validates_presence_of :major, :message => "Operating System version is required"
  validates_presence_of :name
  #TODO: add validation for name and major uniqueness

  before_destroy :ensure_not_used_by_hosts, :ensure_not_used_by_muxes
  alias to_s to_label

  # The OS is usually represented as the catenation of the OS and the revision. E.G. "Solaris 10"
  def to_label
    "#{name} #{major}#{('.' + minor) unless minor.empty?}"
  end

  def to_s
    to_label
  end

  def to_version
    "#{major}#{('-' + minor) unless minor.empty?}"
  end
  alias :to_i :to_label
  
  def to_s
    to_label
  end

  def fullname
    "#{name}_#{to_version}"
  end

  def self.build_from_facts host
    nameindicator = nil
    os_name = host.fv(:operatingsystem)
     if os_name == "Solaris"
       os_major, os_minor = host.fv(:operatingsystemrelease).split(".")
       nameindicator = "u"
     else
       return nil if host.fv(:lsbdistrelease).nil? or host.fv(:lsbdistrelease)!~/^\d/
       os_major, os_minor  = host.fv(:lsbdistrelease).split(".")
       os_minor = 1 unless os_minor
       nameindicator = "l"
     end
     Operatingsystem.find_or_create_by_name_and_major_and_minor os_name, os_major, os_minor, :nameindicator => nameindicator
  end
  
  private

end
