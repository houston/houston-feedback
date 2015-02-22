Houston.config.add_project_feature :feedback do
  name "Feedback"
  icon "fa-comment"
  path { |project| Houston::Feedback::Engine.routes.url_helpers.project_feedback_path(project) }
end
