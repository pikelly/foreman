class PuppetclassesController < ApplicationController
  active_scaffold :puppetclass do |config|
    config.label = "Puppet classes"
    config.columns = [ :name, :nameindicator, :environments, :valid_architectures, :valid_operatingsystems ]
    config.list.columns = [ :name, :nameindicator, :environments ]
    config.update.columns = [ :name, :nameindicator, :environments ]
    config.create.columns = [ :name, :nameindicator, :environments ]
    config.columns[:environments].form_ui  = :select
    config.columns[:name].description = "The name of the hosttype, for example a puppetmaster"
    config.columns[:environments].description = "The environments which are enabled for this host type"

    #config.nested.add_link("Hosts",                [:hosts])
    config.nested.add_link("Edit os/architecture support",   [:muxes])
    config.nested.add_link("Architectures",        [:valid_architectures])
    config.nested.add_link("Operating systems",    [:valid_operatingsystems])
  end
end
