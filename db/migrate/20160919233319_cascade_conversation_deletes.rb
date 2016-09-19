class CascadeConversationDeletes < ActiveRecord::Migration[5.0]
  def up
    execute <<-SQL
      ALTER TABLE ONLY feedback_snippets
      DROP CONSTRAINT fk_rails_bde07ddc98,
      ADD CONSTRAINT fk_rails_bde07ddc98 FOREIGN KEY (conversation_id) REFERENCES feedback_conversations(id) ON DELETE CASCADE
    SQL
  end

  def down
    execute <<-SQL
      ALTER TABLE ONLY feedback_snippets
      DROP CONSTRAINT fk_rails_bde07ddc98,
      ADD CONSTRAINT fk_rails_bde07ddc98 FOREIGN KEY (conversation_id) REFERENCES feedback_conversations(id)
    SQL
  end
end
