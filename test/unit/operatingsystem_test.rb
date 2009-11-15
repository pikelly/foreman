require 'test_helper'

class OperatingsystemTest < ActiveSupport::TestCase
  fixtures :architectures, :operatingsystems, :puppetclasses, :domains, :environments, :ptables
    
  def setup
    @mux = Mux.create :architecture => architectures(:x86_64),  :operatingsystem => operatingsystems(:centos5_3),
                      :puppetclass => puppetclasses(:base)
  end
  test "should refuse to delete operating systems used by a host" do
    os = operatingsystems(:redhat5_4)
    host = Host.create(:name => "fullname", :ip => "123.123.123.123", :mac => "bbccddeeffaa", :mux => @mux,
      :architecture => architectures(:x86_64),
      :domain => domains(:brs), :environment => environments(:production), :ptable => ptables(:default), :operatingsystem => os)
    assert Operatingsystem.all.include?(os) 
    assert_equal  false, os.destroy
    puts os.errors.full_messages.join("\n")
    assert Operatingsystem.all.include?(os)
  end

  test "should refuse to delete operating systems used by a mux" do
    os = operatingsystems(:redhat5_4)
    mux = Mux.create(:operatingsystem => os, :architecture => architectures(:x86_64), :puppetclass =>  puppetclasses(:base))
    assert Operatingsystem.all.include?(os) 
    assert_equal  false, os.destroy
    puts os.errors.full_messages.join("\n")
    assert Operatingsystem.all.include?(os)
  end

  test "should be able to access its hosts" do
    os = operatingsystems(:centos5_3)
    a = Host.create(:name => "fullname1", :ip => "123.123.123.1", :mac => "bbccddeeff11", :operatingsystem => os, :mux => @mux,
      :domain => domains(:brs), :environment => environments(:production), :ptable => ptables(:default), :architecture => architectures(:x86_64))
    b = Host.create(:name => "fullname2", :ip => "123.123.123.2", :mac => "bbccddeeff22", :operatingsystem => os, :mux => @mux,
      :domain => domains(:brs), :environment => environments(:production), :ptable => ptables(:default), :architecture => architectures(:x86_64))
    assert os.hosts(true).map{|host| host.name}.sort == ["fullname1.brs.somewhere.com", "fullname2.brs.somewhere.com"]
  end
  
  test "should be able to access its valid puppetclasses" do
    os = operatingsystems(:centos5_3)
    mx = Mux.create(:operatingsystem => os, :architecture => architectures(:x86_64), :puppetclass =>  puppetclasses(:base))
    mx = Mux.create(:operatingsystem => os, :architecture => architectures(:x86_64), :puppetclass =>  puppetclasses(:apache))
    assert os.valid_puppetclasses(true).map{|pc| pc.name}.sort == ["apache", "base"]
  end

  test "should be able to access its valid_architectures" do
    os = operatingsystems(:centos5_3)
    a = Mux.create(:operatingsystem => os, :architecture => architectures(:x86_64), :puppetclass =>  puppetclasses(:base))
    b = Mux.create(:operatingsystem => os, :architecture => architectures(:sparc),  :puppetclass =>  puppetclasses(:base))
    assert os.valid_architectures(true).map{|arch| arch.name}.sort == ["sparc", "x86_64"]
  end
  
  test "should be able to access its architectures" do
    os = operatingsystems(:centos5_3)
    a = Host.create(:name => "fullname1", :ip => "123.123.123.1", :mac => "bbccddeeff11", :operatingsystem => os, :mux => @mux,
      :domain => domains(:brs), :environment => environments(:production), :ptable => ptables(:default), :architecture => architectures(:x86_64))
    b = Host.create(:name => "fullname2", :ip => "123.123.123.2", :mac => "bbccddeeff22", :operatingsystem => os, :mux => @mux,
      :domain => domains(:brs), :environment => environments(:production), :ptable => ptables(:default), :architecture => architectures(:sparc))
    assert os.architectures(true).map{|arch| arch.name}.sort == ["sparc", "x86_64"]
  end
  
end
