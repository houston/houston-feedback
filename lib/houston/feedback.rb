require "houston/feedback/engine"
require "houston/feedback/configuration"

module Houston
  module Feedback
    extend self

    def config(&block)
      @configuration ||= Feedback::Configuration.new
      @configuration.instance_eval(&block) if block_given?
      @configuration
    end

  end
end
