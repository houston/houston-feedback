module Houston
  module Feedback
    class CommentUserFlags < ActiveRecord::Base
      self.table_name = "feedback_comments_user_flags"

      belongs_to :comment, class_name: "Houston::Feedback::Comment"
      belongs_to :user

    end
  end
end
