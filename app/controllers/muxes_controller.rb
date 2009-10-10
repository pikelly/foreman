class MuxesController < ApplicationController
  active_scaffold :mux do |config|
    config.actions.exclude :show
    config.label = "Valid architecture/operating system combinations "
    config.columns[:operatingsystem].label = "Operating system"
    config.columns = %w{ puppetclass operatingsystem architecture }
    config.columns[:operatingsystem].form_ui  = :select
    config.columns[:architecture].form_ui  = :select
  end
end
