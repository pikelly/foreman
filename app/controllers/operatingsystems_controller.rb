class OperatingsystemsController < ApplicationController
  helper :operatingsystem
  active_scaffold :operatingsystem do |config|
    config.label = "Operating systems"
    config.columns = [:name, :major, :medias, :minor, :nameindicator, :ptables, :architectures ]
    config.list.columns = [:name, :major, :minor, :medias, :nameindicator, :ptables ]
    config.update.columns = [:name, :major, :minor, :medias, :nameindicator, :ptables ]
    config.create.columns  << [:major, :minor]
    config.columns[:ptables].form_ui  = :select
    config.columns[:ptables].label = "Partition tables"
    config.columns[:architectures].form_ui  = :select
    config.columns[:medias].form_ui  = :select
    config.columns[:name].description = "Operating System name, e.g. CentOS"
    config.columns[:major].description = "The OS major version e.g. 5"
    config.columns[:medias].description = "Valid medias for this host"
    config.columns[:medias].label = "Installation medias"
    config.columns[:minor].description = "The OS minor version e.g. 3, leave blank if empty"
    config.columns[:nameindicator].description = "optional, only if a nameing standard is enforced per operatingsystem"
    config.nested.add_link("Hosts", [:hosts])
    config.nested.add_link("Architectures", [:architectures])
  end
end
