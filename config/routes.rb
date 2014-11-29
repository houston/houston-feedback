Houston::Feedback::Engine.routes.draw do
  
  get "by_project/:slug", to: "project_feedback#index", as: :project_feedback
  post "by_project/:slug", to: "project_feedback#create"
  post "by_project/:slug/csv", to: "project_feedback#upload_csv", as: :upload_project_feedback
  post "by_project/:slug/import", to: "project_feedback#import"
  post "by_project/:slug/from_email", to: "project_feedback#from_email"
  
  delete "comments", to: "comments#destroy"
  
  delete "comments/tags", to: "tags#remove"
  post "comments/tags", to: "tags#add"
  
end
