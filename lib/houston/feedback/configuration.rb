module Houston::Feedback
  class Configuration
    
    def initialize
      config = Houston.config.module(:feedback).config
      instance_eval(&config) if config
    end
    
    # Define configuration DSL here
    
  end
end
