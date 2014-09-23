require "houston/feedback/engine"
require "houston/feedback/configuration"

module Houston
  module Feedback
    extend self
    
    attr_reader :config
    
  end
  
  Feedback.instance_variable_set :@config, Feedback::Configuration.new
end
