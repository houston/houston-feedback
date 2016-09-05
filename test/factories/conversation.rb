FactoryGirl.define do
  factory :conversation, class: Houston::Feedback::Conversation do
    project { Project["test"] }
    user { User.find_by_email "admin@example.com" }
    text "lorem ispum"
  end
end
