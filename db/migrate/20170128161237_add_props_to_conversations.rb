class AddPropsToConversations < ActiveRecord::Migration[5.0]
  def change
    add_column :feedback_conversations, :props, :jsonb, default: {}
  end
end
