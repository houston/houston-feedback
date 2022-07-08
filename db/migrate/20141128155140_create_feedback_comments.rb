class CreateFeedbackComments < ActiveRecord::Migration[4.2]
  def up
    create_table :feedback_comments do |t|
      t.integer :project_id, null: false
      t.integer :user_id

      t.text :text, null: false
      t.text :plain_text, null: false
      t.string :customer, null: false, default: ""
      t.text :tags, null: false, default: ""
      t.string :import

      t.tsvector :search_vector

      t.integer :ticket_id

      t.timestamps
    end

    execute "CREATE INDEX index_feedback_comments_on_tsvector ON feedback_comments USING GIN(search_vector)"
  end

  def down
    execute "DROP TRIGGER IF EXISTS index_feedback_comments_on_insert_update_trigger ON feedback_comments"
    execute "DROP FUNCTION IF EXISTS index_feedback_comments_on_insert_update()"

    drop_table :feedback_comments
  end
end
