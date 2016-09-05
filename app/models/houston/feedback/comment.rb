module Houston
  module Feedback
    class Comment < ActiveRecord::Base
      self.table_name = "feedback_comments"

      belongs_to :conversation, class_name: "Houston::Feedback::Conversation"
      belongs_to :user

      validates :conversation, :user, :text, presence: true

      default_scope -> { order(created_at: :desc) }

    end
  end
end
