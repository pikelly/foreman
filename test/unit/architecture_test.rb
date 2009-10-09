require 'test_helper'

class ArchitectureTest < ActiveSupport::TestCase
  fixtures :architectures, :operatingsystems, :puppetclasses, :domains, :environments, :ptables, :hostgroups

  test "should refuse duplicate names" do
    arch = Architecture.create :name => "x86_64"
    assert_equal arch.errors[:name], "has already been taken"
  end

  test "should refuse to delete architectures used by a host" do
    arch = architectures(:x86_64)
    # An architecture can be used by a host directly
    host = Host.create(:name => "fullname", :ip => "123.123.123.123", :mac => "bbccddeeffaa", 
      :domain => domains(:brs), :environment => environments(:production), :ptable => ptables(:default), :architecture => arch)
    assert Architecture.all.include?(arch) 
    assert_equal  false, arch.destroy
    puts arch.errors.full_messages.join("\n")
    assert Architecture.all.include?(arch)
  end

  test "should refuse to delete architectures used by a mux" do
    arch = architectures(:x86_64)
    # An architecture can be used by a host directly or by an OS
    mx = Mux.create(:operatingsystem => operatingsystems(:redhat5_4), :architecture => arch, :puppetclass =>  puppetclasses(:base))
    assert Architecture.all.include?(arch) 
    assert_equal  false, arch.destroy
    puts arch.errors.full_messages.join("\n")
    assert Architecture.all.include?(arch)
  end
  
  test "should be able to access its hosts" do
    arch = architectures(:x86_64)
    a = Host.create(:name => "fullname1", :ip => "123.123.123.1", :mac => "bbccddeeff11", 
      :domain => domains(:brs), :environment => environments(:production), :ptable => ptables(:default), :architecture => arch)
    b = Host.create(:name => "fullname2", :ip => "123.123.123.2", :mac => "bbccddeeff22", 
      :domain => domains(:brs), :environment => environments(:production), :ptable => ptables(:default), :architecture => arch)
    assert arch.hosts(true).map{|host| host.name}.sort == ["fullname1.brs.somewhere.com", "fullname2.brs.somewhere.com"]
  end
  
  test "should be able to access its puppetclasses" do
    arch = architectures(:x86_64)
    mx = Mux.create(:operatingsystem => operatingsystems(:redhat5_4), :architecture => arch, :puppetclass =>  puppetclasses(:base))
    mx = Mux.create(:operatingsystem => operatingsystems(:redhat5_4), :architecture => arch, :puppetclass =>  puppetclasses(:apache))
    assert arch.puppetclasses(true).map{|pc| pc.name}.sort == ["apache", "base"]
  end

  test "should be able to access its operatingsystems" do
    arch = architectures(:x86_64)
    a = Mux.create(:operatingsystem => operatingsystems(:redhat5_4), :architecture => arch, :puppetclass =>  puppetclasses(:base))
    b = Mux.create(:operatingsystem => operatingsystems(:centos5_3), :architecture => arch, :puppetclass =>  puppetclasses(:base))
    assert arch.operatingsystems(true).map{|os| os.to_s}.sort == ["Centos 5.3", "RedHat 5.4"]
  end
  
  
end
