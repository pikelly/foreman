class MuxesController < ApplicationController
  active_scaffold :mux do |config|
    config.label = "Kernel architectures"
    config.columns[:operatingsystem].label = "Operating system"
    config.columns = %w{ operatingsystem architecture }
    config.columns[:operatingsystem].form_ui  = :select
    config.columns[:architecture].form_ui  = :select
    config.nested.add_link("Hosts", [:hosts])
  end
end
