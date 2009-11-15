class EnvironmentsController < ApplicationController
  active_scaffold :environment do |config|
    config.actions.exclude :show
    config.columns = %w{name}
    config.nested.add_link("Hosts", [:hosts])
    config.nested.add_link("Classes", [:puppetclasses])
  end
end
