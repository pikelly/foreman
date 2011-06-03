class Conflict
  include Orchestration::Common

  attr_accessor :colliding_host, :host, :conflicting, :queue, :missing, :ip, :kind
  alias_method :conflicting?, :conflicting
  alias_method :missing?, :missing

  def initialize *args
    raise "abstract"
  end

  def resolv
    raise "abstract"
  end

  def validate
    raise "abstract"
  end

  def conflicting?
    @conflicting
  end

  def logger
    Rails.logger
  end
end
