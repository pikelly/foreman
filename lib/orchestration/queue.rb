require 'task'
module Orchestration
  # Represents tasks queue for orchestration
  class Queue

    attr_reader :items
    STATUS = %w[ pending running failed completed rollbacked ]

    def initialize
      @items = []
    end

    def create options
      options[:status] ||= default_status
      items << Task.new(options)
    end

    def delete item
      @items.delete item
    end

    def find_by_name name
      items.each {|task| return task if task.name == name}
    end

    def all
      items.sort
    end

    def count
      items.count
    end

    def empty?
      items.empty?
    end

    def clear
      @items = [] && true
    end

    STATUS.each do |s|
      define_method s do
        all.delete_if {|t| t.status != s}.sort
      end
    end

    # Handles the actual queue
    # takes care for running the tasks in order
    # if any of them fail, it rollbacks all completed tasks
    # in order not to keep any left overs in our proxies.
    def process runner
      return true if Rails.env == "test" and !runner.test_process_code
      # queue is empty - nothing to do.
      return if empty?

      # process all pending tasks
      pending.each do |task|
        # if we have failures, we don't want to process any more tasks
        next unless failed.empty?
        task.status = "running"
        begin
          task.status = execute({:action => task.action}) ? "completed" : "failed"

        rescue => e
          task.status = "failed"
          failed "failed #{e}"
        end
      end

      # if we have no failures - we are done
      return true if failed.empty? and pending.empty? and runner.errors.empty?

      Rails.logger.debug "Rolling back due to a problem: #{failed}"
      # handle errors
      # we try to undo all completed operations and trigger a DB rollback
      (completed + running).sort.reverse_each do |task|
        begin
          task.status = "rollbacked"
          execute({:action => task.action, :rollback => true})
        rescue => e
          # if the operation failed, we can just report upon it
          failed "Failed to perform rollback on #{task.name} - #{e}"
        end
      end

      rollback
    end

    def execute opts = {}
      obj, met = opts[:action]
      rollback = opts[:rollback] || false
      # at the moment, rollback are expected to replace set with del in the method name
      if rollback
        met = met.to_s
        case met
        when /set/
          met.gsub!("set","del")
        when /del/
          met.gsub!("del","set")
        else
          raise "Dont know how to rollback #{met}"
        end
        met = met.to_sym
      end
      if obj.respond_to?(met)
        return obj.send(met)
      else
        failed "invalid method #{met}"
        raise "invalid method #{met}"
      end
    end

    private

    def rollback
      raise ActiveRecord::Rollback
    end

    def default_status
      "pending"
    end
  end
end
