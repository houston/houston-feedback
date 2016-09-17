class CreateFeedbackSnippets < ActiveRecord::Migration[5.0]
  def up
    create_table :feedback_snippets do |t|
      t.belongs_to :conversation, null: false, foreign_key: { to_table: :feedback_conversations }

      t.integer :range, array: true, null: true
      t.text :text, null: false
      t.text :tags, null: false, default: ""
      t.tsvector :search_vector

      t.timestamps
    end

    execute "CREATE INDEX index_feedback_snippets_on_search_vector ON feedback_snippets USING GIN(search_vector)"


    # Deprecate feedback_conversations.search_vector

    rename_column :feedback_conversations, :search_vector, :__search_vector


    # When a Feedback is added, create its initial snippet

    execute <<-SQL
    CREATE FUNCTION create_snippet_for_conversation() RETURNS trigger LANGUAGE plpgsql AS $$
    BEGIN
      INSERT INTO feedback_snippets (conversation_id, text, search_vector, created_at, updated_at)
      SELECT
        new.id,
        new.plain_text,
        setweight(to_tsvector('english', new.plain_text), 'B') ||
        setweight(to_tsvector('english', new.attributed_to), 'B'),
        new.created_at,
        new.updated_at;
      return new;
    END;
    $$;

    CREATE TRIGGER create_snippet_for_conversation_on_insert_trigger AFTER INSERT
      ON feedback_conversations
      FOR EACH ROW EXECUTE PROCEDURE create_snippet_for_conversation();
    SQL


    # Create initial snippets for existing feedback

    require "progressbar"
    connection = Houston::Feedback::Conversation.connection
    conversations = Houston::Feedback::Conversation.all
    pbar = ProgressBar.new("progress", conversations.count)
    conversations.in_batches do |conversations|
      conversations.pluck(:id).each do |id|
        connection.execute <<-SQL
          INSERT INTO feedback_snippets (conversation_id, text, search_vector, created_at, updated_at)
          SELECT id, plain_text, __search_vector, created_at, updated_at
          FROM feedback_conversations
          WHERE feedback_conversations.id=#{id}
        SQL
        pbar.inc
      end
    end
    pbar.finish
  end

  def down
    drop_table :feedback_snippets

    rename_column :feedback_conversations, :__search_vector, :search_vector

    execute "DROP TRIGGER IF EXISTS create_snippet_for_conversation_on_insert_trigger ON feedback_conversations"
    execute "DROP FUNCTION IF EXISTS create_snippet_for_conversation()"
  end
end
