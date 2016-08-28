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



  register_events {{
    "feedback:comment:create"   => params("comment").desc("A new Feedback was added"),
    "feedback:comments:import"  => params("comments").desc("Feedback was imported")
  }}



  add_project_feature :feedback do
    name "Feedback"
    path { |project| Houston::Feedback::Engine.routes.url_helpers.project_feedback_path(project) }
  end



  add_user_option "feedback.digest" do
    name "Feedback"
    html do |f|
      <<-HTML
      <p class="instructions">
        for projects I follow, send me a digest of new feedback:
      </p>

      #{f.label("feedback.digest_never",  class: "radio") { f.radio_button(:"feedback.digest", "never")  + " Never" }}
      #{f.label("feedback.digest_daily",  class: "radio") { f.radio_button(:"feedback.digest", "daily")  + " Daily" }}
      #{f.label("feedback.digest_weekly", class: "radio") { f.radio_button(:"feedback.digest", "weekly") + " Weekly" }}
      HTML
    end
  end



end
