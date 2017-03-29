class CreateTableFeedbackVersions < ActiveRecord::Migration[5.0]
  def self.up
    execute <<~SQL
      CREATE TABLE feedback_versions AS SELECT * FROM versions
        WHERE versioned_type in ('Houston::Feedback::Comment', 'Houston::Feedback::Conversation')
    SQL

    change_table :feedback_versions do |t|
      t.index [:versioned_id, :versioned_type]
      t.index [:user_id, :user_type]
      t.index :user_name
      t.index :number
      t.index :tag
      t.index :created_at
    end
  end

  def self.down
    drop_table :feedback_versions
  end
end
