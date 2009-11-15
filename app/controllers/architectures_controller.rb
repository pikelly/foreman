class ArchitecturesController < ApplicationController
  active_scaffold :architecture do |config|
    config.actions.exclude :show
    config.columns      = %w{ name valid_puppetclasses operatingsystems}
    # It appears that you may not remove the puppetclasses entry below otherwise AS breaks
    config.list.columns = %w{ name valid_puppetclasses }
    config.update.columns = %w{ name }
    config.create.columns = %w{ name }
    config.columns[:valid_puppetclasses].form_ui  = :select
    config.columns[:operatingsystems].form_ui  = :select

    config.nested.add_link("Hosts",             [:hosts])
    config.nested.add_link("Operating systems", [:operatingsystems])
  end
end
