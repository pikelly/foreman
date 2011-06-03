require_dependency "proxy_api"
require 'orchestration/queue'

module Orchestration
  def self.included(base)
    base.send :include, InstanceMethods
    base.class_eval do
      attr_reader :queue, :old
      attr_accessor :test_process_code
      # stores actions to be performed on our proxies based on priority
      before_validation :set_queue
      before_validation :setup_clone

      # extend our Host model to know how to handle subsystems
      include Orchestration::DHCP
      include Orchestration::DNS
      include Orchestration::TFTP
      include Orchestration::Puppetca
      include Orchestration::Libvirt

      # save handles both creation and update of hosts
      before_save :on_save
      after_destroy :on_destroy
    end
  end

  module InstanceMethods

    include Orchestration::Common
    protected

    def on_save
      #queue should always be set, but when testing and you have stubbed valid?, queue may be nil
      queue.process self if queue
    end

    def on_destroy
      errors.empty? ? queue.process(self) : false
    end

    public

    # Rebuilds the host's network database entries based upon the ConflictList object
    def regenerate conflicts
      return false unless initialize_dns
      return false unless initialize_dhcp
      return false if tftp? and !initialize_tftp

      set_queue

      for conflict in conflicts.cleanup(:regenerate)
        conflict.regenerate self
      end
      return false unless errors.empty?

      run_queue
    end

    # we override this method in order to include checking the
    # after validation callbacks status, as rails by default does
    # not care about their return status.
    def valid?
      super
      errors.empty?
    end

    # we override the destroy method, in order to ensure our queue exists before other callbacks
    # and to process the queue only if we found no errors
    def destroy
      set_queue
      super
    end

    private
    # we keep the before update host object in order to compare changes
    def setup_clone
      return if new_record?
      @old = clone
      for key in (changed_attributes.keys - ["updated_at"])
        @old.send "#{key}=", changed_attributes[key]
        # At this point the old cached bindings may still be present so we force an AR association reload
        # This logic may not work or be required if we switch to Rails 3
        if (match = key.match(/^(.*)_id$/))
          name = match[1].to_sym
          next if name == :owner # This does not work for the owner association even from the console
          self.send(name, true) if (send(name) and send(name).id != @attributes[key])
          old.send(name, true)  if (old.send(name) and old.send(name).id != old.attributes[key])
        end
      end
    end

  end
end
