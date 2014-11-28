Rails.application.routes.draw do

  mount Houston::Feedback::Engine => "/feedback"

end
