Houston::Feedback::Engine.routes.draw do
  
  get "by_project/:slug", to: "project_feedback#index", as: :project_feedback
  
  delete "comments/tags", to: "tags#remove"
  post "comments/tags", to: "tags#add"
  
end
