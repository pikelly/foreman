class Architecture < ActiveRecord::Base
  has_many :muxes, :dependent => :destroy
  
  has_many :hosts,            :through => :muxes
  has_many :operatingsystems, :through => :muxes, :uniq =>true
  has_many :puppetclasses,    :through => :muxes, :uniq =>true
  
  validates_uniqueness_of :name
  before_destroy :ensure_not_used

  def to_s
    name
  end 
  alias :to_i :to_s
end
