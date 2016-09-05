class RenameFeedbackCommentsToFeedbackConversations < ActiveRecord::Migration[5.0]
  def up
    rename_table :feedback_comments, :feedback_conversations
    rename_table :feedback_comments_user_flags, :feedback_user_flags
    rename_column :feedback_user_flags, :comment_id, :conversation_id
  end

  def down
    rename_column :feedback_user_flags, :conversation_id, :comment_id
    rename_table :feedback_user_flags, :feedback_comments_user_flags
    rename_table :feedback_conversations, :feedback_comments
  end
end
