require 'test_helper'

class HostTest < ActiveSupport::TestCase
  fixtures :operatingsystems, :domains, :puppetclasses, :architectures, :ptables
  
  def setup
    @mux =  Mux.find_or_create_by_operatingsystem_id_and_architecture_id_and_puppetclass_id(
         :operatingsystem => operatingsystems(:redhat5_4),
         :architecture => architectures(:x86_64),
         :puppetclass => puppetclasses(:base))
    
    @hostgroup = Hostgroup.new(:name => "host-logmon")
    @hostgroup.puppetclasses << puppetclasses(:base)
    @hostgroup.puppetclasses << puppetclasses(:apache)
    @hostgroup.save!
  end
  test "should not save without a hostname" do
    host = Host.new
    assert !host.save
  end

  test "should fix mac address" do
    host = Host.create :name => "myhost", :mac => "aabbccddeeff"
    assert_equal "aa:bb:cc:dd:ee:ff", host.mac
  end

  test "should fix ip address if a leading zero is used" do
    host = Host.create :name => "myhost", :mac => "aabbccddeeff", :ip => "123.01.02.03"
    assert_equal "123.1.2.3", host.ip
  end

  test "should add domain name to hostname" do
    host = Host.create :name => "myhost", :mac => "aabbccddeeff", :ip => "123.01.02.03",
      :domain => domains(:brs)
    assert_equal "myhost.brs.somewhere.com", host.name
  end

  test "should be able to save host" do
    host = Host.create :name => "myfullhost", :mac => "aabbecddeeff", :ip => "123.05.02.03",
      :domain      => domains(:brs), 
      :environment => Environment.first,
      :hostgroup   => @hostgroup,
      :ptable      => ptables(:default)
    puts host.errors.full_messages
    assert host.valid?
  end

  test "should import facts from yaml stream" do
    h=Host.new(:name => "sinn1636.lan")
    h.disk = "!" # workaround for now
    h.importFacts YAML::load(File.read(File.expand_path(File.dirname(__FILE__) + "/facts.yml")))
    assert h.valid?
  end

  test "should import facts from yaml of a new host" do
    assert Host.importHostAndFacts File.read(File.expand_path(File.dirname(__FILE__) + "/facts.yml"))
  end


  test "should not save if both ptable and disk are not defined" do
    host = Host.create :name => "myfullhost", :mac => "aabbecddeeff", :ip => "123.05.02.03",
      :domain => domains(:brs), :hostgroup => @hostgroup, :environment => Environment.first
    assert !host.valid?
  end

  test "should save if ptable is defined" do
    host = Host.create :name => "myfullhost", :mac => "aabbecddeeff", :ip => "123.05.02.03",
      :domain => domains(:brs), :hostgroup => @hostgroup, :environment => Environment.first, :ptable => Ptable.first
    assert host.valid?
  end

  test "should save if disk is defined" do
    host = Host.create :name => "myfullhost", :mac => "aabbecddeeff", :ip => "123.05.02.03",
      :domain => domains(:brs), :hostgroup => @hostgroup, :environment => Environment.first, :disk => "aaa"
    assert host.valid?
  end

  test "should import from external nodes output" do
    # create a dummy node
    host = Host.create :name => "myfullhost", :mac => "aabbecddeeff", :ip => "123.05.02.03",
      :domain => domains(:brs), :operatingsystem => Operatingsystem.first,
      :architecture => Architecture.first, :environment => Environment.first, :disk => "aaa",
      :hostgroup => @hostgroup

    # dummy external node info
    nodeinfo = {"parameters"=>{"puppetmaster"=>"puppet", "MYVAR"=>"value"}, "classes"=>["base","apache"]}

    host.importNode nodeinfo
    nodeinfo["parameters"] = nodeinfo["parameters"].merge('domainname' => "Bristol")
    assert host.info == nodeinfo
  end
end
