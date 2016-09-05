Houston::Feedback::Engine.routes.draw do

  scope "feedback" do
    get ":id", to: "conversations#show"

    get "by_project/:slug", to: "project_feedback#index", as: :project_feedback
    post "by_project/:slug", to: "project_feedback#create"
    post "by_project/:slug/csv", to: "project_feedback#upload_csv", as: :upload_project_feedback
    post "by_project/:slug/import", to: "project_feedback#import"
    post "by_project/:slug/from_email", to: "project_feedback#from_email"
    get "by_project/:slug/history", to: "project_feedback#history"

    delete "conversations", to: "conversations#destroy"
    post "conversations/move", to: "conversations#move"

    post "conversations/:id/read", to: "conversations#mark_read"
    post "conversations/:id/unread", to: "conversations#mark_unread"
    put "conversations/:id/signal_strength", to: "conversations#signal_strength"
    put "conversations/:id", to: "conversations#update"

    delete "conversations/tags", to: "tags#remove"
    post "conversations/tags", to: "tags#add"

    post "customers", to: "customers#create"
    post "customers/:id/attribution", to: "customers#add_attribution"
  end

end
