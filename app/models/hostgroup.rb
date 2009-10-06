class Hostgroup < ActiveRecord::Base
  has_and_belongs_to_many :puppetclasses
  has_many :hosts

  validates_uniqueness_of :name
  has_many :group_parameters, :dependent => :destroy


#TODO: add a method that returns the valid os for a hostgroup
  def operatingsystems
  end

end
