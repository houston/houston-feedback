class FeedbackCommentsReadReceipts < ActiveRecord::Migration
  def change
    create_table :feedback_comments_read_receipts do |t|
      t.integer :user_id, null: false
      t.integer :comment_id, null: false
      
      t.timestamps
      
      t.index [:user_id, :comment_id], unique: true
    end
  end
end
