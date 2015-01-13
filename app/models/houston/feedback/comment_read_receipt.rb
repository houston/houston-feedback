module Houston
  module Feedback
    class CommentReadReceipt < ActiveRecord::Base
      self.table_name = "feedback_comments_read_receipts"
      
      belongs_to :comment, class_name: "Houston::Feedback::Comment"
      belongs_to :user
      
    end
  end
end
