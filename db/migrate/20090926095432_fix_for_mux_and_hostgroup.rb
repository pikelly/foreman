class FixForMuxAndHostgroup < ActiveRecord::Migration
  def self.up
    add_column :hosts, :architecture_id, :integer
    add_column :hosts, :operatingsystem_id, :integer
  end

  def self.down
    remove_column :hosts, :architecture_id
    remove_column :hosts, :operatingsystem_idS
  end
end
