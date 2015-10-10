class FeedbackCommentsUserFlags < ActiveRecord::Migration
  def change
    create_table :feedback_comments_user_flags do |t|
      t.integer :user_id, null: false
      t.integer :comment_id, null: false

      t.boolean :read, default: false

      t.timestamps

      t.index [:user_id, :comment_id], unique: true
    end
  end
end
