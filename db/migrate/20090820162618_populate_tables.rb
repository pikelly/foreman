class PopulateTables < ActiveRecord::Migration
  def self.up
    Architecture.create :name => "sparc"
    
    centos_5   = Operatingsystem.create :name => "Centos",  :major => 5,  :minor => "",       :nameindicator => "l"
    solaris_8  = Operatingsystem.create :name => "Solaris", :major => 8,  :minor => "hw0507", :nameindicator => "u"
    solaris_10 = Operatingsystem.create :name => "Solaris", :major => 10, :minor => "hw0509", :nameindicator => "u"
    
    puppetmaster = Puppetclass.create     :name => "host-puppetmaster", :nameindicator => "a"
    compute      = Puppetclass.create     :name => "host-rd-compute",   :nameindicator => "c"

    i386         = Architecture.find_by_name("i386")
    x86_64       = Architecture.find_by_name("x86_64")
    sparc        = Architecture.find_by_name("sparc")
    
    pm_mux = Mux.create  :operatingsystem => centos_5,   :architecture => i386,   :puppetclass => puppetmaster
    Mux.create  :operatingsystem => centos_5,   :architecture => i386,   :puppetclass => compute
    Mux.create  :operatingsystem => centos_5,   :architecture => x86_64, :puppetclass => compute
    Mux.create  :operatingsystem => solaris_8,  :architecture => sparc,  :puppetclass => compute
    Mux.create  :operatingsystem => solaris_10, :architecture => x86_64, :puppetclass => compute
    Mux.create  :operatingsystem => solaris_10, :architecture => sparc,  :puppetclass => compute
    
    brs = Domain.create :name => "brs", :fullname => "Bristol", :dnsserver => "brssc001.eu.somewhere.com", :gateway => "wsus.vih.somewhre.com"
    vmware =Model.create  :name => "VMWare"
    
    test = Environment.create :name => "test"
    write test.errors.full_messages
    write Host.create(:name => "brsla001", :ip => "1.2.3.4", :mac => "1:2:3:4:5:6", :domain => brs, :environment => test,
    :ptable => Ptable.find_by_name("default"), :media => Media.find(:first), :model => Model.find_by_name("VMWare"), :mux => pm_mux).errors.full_messages 
  end

  def self.down
    (h = Host.find_by_name("brsla001.brs.somewhere.com")       )&& h.destroy  
    (e = Environment.find_by_name("test")                      )&& e.destroy
    (m = Model.find_by_name("VMWare")                          )&& m.destroy  
    (d = Domain.find_by_name("brs")                            )&& d.destroy  
    (p = Puppetclass.find_by_name("host-rd-compute")           )&& p.destroy
    (p = Puppetclass.find_by_name("host-puppetmaster")         )&& p.destroy
    (o = Operatingsystem.find_by_name_and_major("Solaris", 10) )&& o.destroy
    (o = Operatingsystem.find_by_name_and_major("Solaris", 8)  )&& o.destroy
    (o = Operatingsystem.find_by_name_and_major("Centos", 5)   )&& o.destroy
    (a = Architecture.find_by_name("sparc", 5)                 )&& a.destroy
  end
end
