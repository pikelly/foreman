class Karch < ActiveRecord::Base
  belongs_to :architecture
  belongs_to :puppetclass
  belongs_to :operatingsystem
  has_many   :hosts

  def to_s
    "#{operatingsystem.to_i} #{architecture.to_i}"
  end
end
