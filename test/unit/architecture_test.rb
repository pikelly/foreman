require 'test_helper'

class ArchitectureTest < ActiveSupport::TestCase
  fixtures :architectures, :operatingsystems, :puppetclasses, :domains, :environments, :ptables, :hostgroups

  test "should refuse duplicate names" do
    arch = Architecture.create :name => "x86_64"
    assert_equal arch.errors[:name], "has already been taken"
  end

  test "should refuse to delete architectures used by a host" do
    ar = architectures(:x86_64)
    # An architecture can be used by a host directly
    host = Host.create(:name => "fullname", :ip => "123.123.123.123", :mac => "bbccddeeffaa", 
      :domain => domains(:brs), :environment => environments(:production), :ptable => ptables(:default), :architecture => ar)
    assert Architecture.all.include?(ar) 
    assert_equal  false, ar.destroy
    puts ar.errors.full_messages.join("\n")
    assert Architecture.all.include?(ar)
  end

  test "should refuse to delete architectures used by a mux" do
    pc = puppetclasses(:base)
    op = operatingsystems(:redhat5_4)
    ar = architectures(:x86_64)
    # An architecture can be used by a host directly or by an OS
    mx = Mux.create(:operatingsystem => op, :architecture => ar, :puppetclass =>  pc)
    assert Architecture.all.include?(ar) 
    assert_equal  false, ar.destroy
    puts ar.errors.full_messages.join("\n")
    assert Architecture.all.include?(ar)
  end
end
