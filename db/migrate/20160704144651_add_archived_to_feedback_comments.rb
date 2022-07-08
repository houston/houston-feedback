class AddArchivedToFeedbackComments < ActiveRecord::Migration[4.2]
  def up
    add_column :feedback_comments, :archived, :boolean, default: false, null: false

    Houston::Feedback::Conversation.search("#addressed|invalid|no").update_all(archived: true)
  end

  def down
    remove_column :feedback_comments, :archived
  end
end
