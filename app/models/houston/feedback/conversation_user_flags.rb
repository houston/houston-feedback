module Houston
  module Feedback
    class ConversationUserFlags < ActiveRecord::Base
      self.table_name = "feedback_user_flags"

      belongs_to :conversation, class_name: "Houston::Feedback::Conversation"
      belongs_to :user

      validates :signal_strength, inclusion: { in: [1, 2, 3, 4] }, allow_nil: true

      after_save :cache_average_signal_strength, if: :signal_strength_changed?

    private

      def cache_average_signal_strength
        conversation.cache_average_signal_strength!
      end

    end
  end
end
