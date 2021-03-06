# This models the partition tables for a disk layouts
# It supports both static partition maps and dynamic scripts that create partition tables on-the-fly
# A host object may contain a reference to one of these ptables or, alternatively, it may contain a
# modified version of one of these in textual form
class Ptable < ActiveRecord::Base
  has_many :hosts
  has_and_belongs_to_many :operatingsystems
  before_destroy :ensure_not_used
  validates_uniqueness_of :name
  validates_uniqueness_of :layout

end
