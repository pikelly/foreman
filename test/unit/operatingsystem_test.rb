require 'test_helper'

class OperatingsystemTest < ActiveSupport::TestCase
  fixtures :architectures, :operatingsystems, :puppetclasses, :domains, :environments, :ptables
    
  test "should refuse to delete operating systems used by a host" do
    op = operatingsystems(:redhat5_4)
    host = Host.create(:name => "fullname", :ip => "123.123.123.123", :mac => "bbccddeeffaa", 
      :domain => domains(:brs), :environment => environments(:production), :ptable => ptables(:default), :operatingsystem => op)
    assert Operatingsystem.all.include?(op) 
    assert_equal  false, op.destroy
    puts op.errors.full_messages.join("\n")
    assert Operatingsystem.all.include?(op)
  end

  test "should refuse to delete operating systems used by a mux" do
    op = operatingsystems(:redhat5_4)
    mux = Mux.create(:operatingsystem => op, :architecture => architectures(:x86_64), :puppetclass =>  puppetclasses(:base))
    assert Operatingsystem.all.include?(op) 
    assert_equal  false, op.destroy
    puts op.errors.full_messages.join("\n")
    assert Operatingsystem.all.include?(op)
  end


end
