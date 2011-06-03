# These methods are included in Host, (indirectly via Orchestration, ) and ConflictList.
# They provide
module Orchestration
  module Common
    def self.included(base)
      base.class_eval do
        def self.conflict_sources
          Dir["lib/conflicts/*"].map{|d| d.gsub(/lib\/conflicts\/|\.rb/,"")}.map{|c| ("Conflicts::"+c.camelize).constantize}
        end
      end
    end

    protected

    # log and add to errors
    def failure msg, backtrace=nil
      logger.warn(backtrace ? msg + backtrace.join("\n") : msg)
      errors.add_to_base msg
      false
    end

    private

    def proxy_error e
      head = (e.respond_to?(:http_code) and (e.http_code == 409)) ? "CONFLICT:" : ""
      head + ((e.respond_to?(:response) and !e.response.nil?) ? e.response : e)
    end

    def set_queue
      @queue = Orchestration::Queue.new
    end

    def run_queue
      begin
        queue.process self
      rescue ActiveRecord::Rollback
        return false
      end
      errors.empty?
    end

  end
end
