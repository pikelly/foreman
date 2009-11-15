class Operatingsystem < ActiveRecord::Base
  has_many :muxes, :dependent => :destroy
  has_many :medias
  has_and_belongs_to_many :ptables
  
  has_many :hosts,         :through => :muxes
  has_many :architectures, :through => :muxes, :uniq => true
  has_many :puppetclasses, :through => :muxes, :uniq => true
  
  validates_presence_of :major, :message => "Operating System version is required"
  validates_presence_of :name
  #TODO: add validation for name and major uniqueness

  before_destroy :ensure_not_used

  # The OS is usually represented as the catenation of the OS and the revision. E.G. "Solaris 10"
  def to_label
    "#{name} #{major}#{('.' + minor) unless minor.empty?}"
  end

  def to_s
    to_label
  end

  def to_version
    "#{major}#{('-' + minor) unless minor.empty?}"
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
       os_major. os_minor = host.fv(:operatingsystemrelease).split(".")
       nameindicator = "u"
     else
       os_major,os_minor  = host.fv(:lsbdistrelease).split(".")
       os_minor = 1 unless os_minor
       nameindicator = "l"
     end
     Operatingsystem.find_or_create_by_name_and_major_and_minor os_name, os_major, os_minor, :nameindicator => nameindicator
  end
end
