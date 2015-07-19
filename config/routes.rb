Houston::Feedback::Engine.routes.draw do
  
  get "by_project/:slug", to: "project_feedback#index", as: :project_feedback
  post "by_project/:slug", to: "project_feedback#create"
  post "by_project/:slug/csv", to: "project_feedback#upload_csv", as: :upload_project_feedback
  post "by_project/:slug/import", to: "project_feedback#import"
  post "by_project/:slug/from_email", to: "project_feedback#from_email"
  get "by_project/:slug/history", to: "project_feedback#history"
  
  delete "comments", to: "comments#destroy"
  
  post "comments/:id/read", to: "comments#mark_read"
  post "comments/:id/unread", to: "comments#mark_unread"
  put "comments/:id", to: "comments#update"
  
  delete "comments/tags", to: "tags#remove"
  post "comments/tags", to: "tags#add"
  
end
