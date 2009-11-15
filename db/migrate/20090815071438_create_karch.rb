class CreateKarch < ActiveRecord::Migration
  def self.up
    create_table :karches do |t|
      t.references :operatingsystem, :null => false
      t.references :architecture,    :null => false
      t.references :puppetclass
      t.timestamps
    end
    remove_column :puppetclasses, :operatingsystems_id
    
    remove_column :hosts, :architecture_id 
    remove_column :hosts, :operatingsystem_id
    add_column    :hosts, :karch_id, :integer
    
    drop_table :architectures_operatingsystems
    drop_table :operatingsystems_puppetclasses
    drop_table :hosts_puppetclasses
  end

  def self.down
    add_column :puppetclasses, :operatingsystem_id, :integer
    
    add_column :hosts, :operatingsystem_id, :integer
    add_column :hosts, :architectures_id,    :integer
    remove_column :hosts, :karchid_id
    
    add_column :puppetclasses, :operatingsystem_id, :integer

    drop_table :karches
  end
end
