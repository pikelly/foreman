class Mux < ActiveRecord::Base
  belongs_to :architecture
  belongs_to :puppetclass
  belongs_to :operatingsystem
  
  validates_associated :architecture, :puppetclass, :operatingsystem


  def to_s
    "#{operatingsystem.to_i} #{architecture}"
  end
end
