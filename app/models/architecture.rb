class Architecture < ActiveRecord::Base
  has_many :karches, :dependent => :destroy
  
  has_many :hosts,            :through => :karches
  has_many :operatingsystems, :through => :karches
  has_many :puppetclasses,    :through => :karches
  
  validates_uniqueness_of :name
  before_destroy :ensure_not_used

  def to_s
    name
  end 
  alias :to_i :to_s
end
