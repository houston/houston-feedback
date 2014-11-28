Houston.config.add_navigation_renderer :feedback do
  projects = followed_projects.select { |project| can?(:read, project) }
  render_nav_menu "Feedback", icon: "fa-comment", items: projects.map { |project| ProjectMenuItem.new(project, Houston::Feedback::Engine.routes.url_helpers.project_feedback_path(project)) }
end
