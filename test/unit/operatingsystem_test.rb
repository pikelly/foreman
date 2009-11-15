require 'test_helper'

class OperatingsystemTest < ActiveSupport::TestCase
  fixtures :architectures, :operatingsystems, :puppetclasses, :domains, :environments, :ptables
    
  test "should refuse to delete used operating systems" do
    op = operatingsystems(:redhat5_4)
    mux = Mux.create(:operatingsystem => op, :architecture => architectures(:x86_64), :puppetclass =>  puppetclasses(:one))
    host = Host.create(:mux => mux, :name => "fullname", :ip => "123.123.123.123", :mac => "bbccddeeffaa", 
      :domain => domains(:brs), :environment => environments(:production), :ptable => ptables(:default))
    assert Operatingsystem.all.include?(op) 
    assert_equal  false, op.destroy
    assert Architecture.all.include?(op)
  end
end
