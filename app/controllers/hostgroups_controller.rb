class HostgroupsController < ApplicationController
  active_scaffold :hostgroups do |config|
    config.label = "Host Groups"
    config.columns = [ :name, :puppetclasses, :group_parameters]
    config.list.columns = [ :name, :group_parameters]
    config.columns[:name].description = "The name of the group"
    config.columns[:puppetclasses].form_ui  = :select
    config.nested.add_link("puppet classes",        [:puppetclasses])

  end

end
