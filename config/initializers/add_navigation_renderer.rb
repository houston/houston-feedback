Houston.config.add_navigation_renderer :feedback do
  projects = followed_projects.select { |project| can?(:read, project) }
  unless projects.empty?
    menu_items = []
    menu_items << MenuItem.new("All", Houston::Feedback::Engine.routes.url_helpers.all_feedback_path)
    menu_items << MenuItemDivider.new
    menu_items.concat projects.map { |project| ProjectMenuItem.new(project, Houston::Feedback::Engine.routes.url_helpers.project_feedback_path(project)) }
    menu_items
    
    render_nav_menu "Feedback", icon: "fa-comment", items: menu_items
  end
end
