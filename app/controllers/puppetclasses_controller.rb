class PuppetclassesController < ApplicationController
  active_scaffold :puppetclass do |config|
    config.label = "Puppet classes"
    config.columns = [ :name, :nameindicator, :environments, :architectures, :operatingsystems ]
    config.list.columns = [ :name, :nameindicator, :environments ]
    config.update.columns = [ :name, :nameindicator, :environments ]
    config.create.columns = [ :name, :nameindicator, :environments ]
    config.columns[:environments].form_ui  = :select
    config.columns[:name].description = "The name of the hosttype, for example a puppetmaster"
    config.columns[:environments].description = "The environments which are enabled for this host type"

    #config.nested.add_link("Hosts",                [:hosts])
    config.nested.add_link("valid combinations",   [:muxes])
    config.nested.add_link("Architectures",        [:architectures])
    config.nested.add_link("Operating systems",    [:operatingsystems])
  end
end
