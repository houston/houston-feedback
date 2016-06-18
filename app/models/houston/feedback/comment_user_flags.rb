module Houston
  module Feedback
    class CommentUserFlags < ActiveRecord::Base
      self.table_name = "feedback_comments_user_flags"

      belongs_to :comment, class_name: "Houston::Feedback::Comment"
      belongs_to :user

      validates :signal_strength, inclusion: { in: [1, 2, 3, 4] }, allow_nil: true

      after_save :cache_average_signal_strength, if: :signal_strength_changed?

    private

      def cache_average_signal_strength
        comment.cache_average_signal_strength!
      end

    end
  end
end
