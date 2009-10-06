class Architecture < ActiveRecord::Base
  has_many :muxes
  has_many :hosts
  
  has_many :operatingsystems, :through => :muxes, :uniq =>true
  has_many :puppetclasses,    :through => :muxes, :uniq =>true
  
  validates_uniqueness_of :name
  before_destroy :ensure_not_used_by_hosts, :ensure_not_used_by_muxes

  def to_s
    name
  end 

  private

end
