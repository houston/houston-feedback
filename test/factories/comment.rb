FactoryGirl.define do
  factory :comment, class: Houston::Feedback::Comment do
    project { Project["test"] }
    user { User.find_by_email "admin@example.com" }
    text "lorem ispum"
  end
end
