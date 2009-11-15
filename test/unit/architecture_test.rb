require 'test_helper'

class ArchitectureTest < ActiveSupport::TestCase
  fixtures :architectures, :operatingsystems, :puppetclasses, :domains, :environments, :ptables

  test "should refuse duplicate names" do
    arch = Architecture.create :name => "x86_64"
    assert_equal arch.errors[:name], "has already been taken"
  end

  test "should refuse to delete used architectures" do
    pc = puppetclasses(:base)
    op = operatingsystems(:redhat5_4)
    ar = architectures(:x86_64)
    mx = Mux.create(:operatingsystem => op, :architecture => ar, :puppetclass =>  pc)
    host = Host.create(:mux => mx, :name => "fullname", :ip => "123.123.123.123", :mac => "bbccddeeffaa", 
      :domain => domains(:brs), :environment => environments(:production), :ptable => ptables(:default))
    puts host.architecture
    puts Architecture.first.hosts.first.architecture
    puts ar.hosts.first.architecture
    puts "Count = #{ar.hosts(true).count}"
    puts ar.to_s
    assert Architecture.all.include?(ar) 
    assert_equal  false, ar.destroy
    assert Architecture.all.include?(ar)
  end
end
