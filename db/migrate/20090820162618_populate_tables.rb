class PopulateTables < ActiveRecord::Migration
  def self.up
    Architecture.create :name => "sparc"
    Model.create        :name => "VMWare"
    Environment.create  :name => "test"
  end

  def self.down
    (e = Environment.find_by_name("test")                      )&& e.destroy
    (m = Model.find_by_name("VMWare")                          )&& m.destroy  
    (a = Architecture.find_by_name("sparc", 5)                 )&& a.destroy
  end
end
