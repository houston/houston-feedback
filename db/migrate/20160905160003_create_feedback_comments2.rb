class CreateFeedbackComments2 < ActiveRecord::Migration[5.0]
  def change
    create_table :feedback_comments do |t|
      t.references :conversation, null: false
      t.references :user, null: false
      t.text :text, null: false, default: ""

      t.timestamps
    end
  end
end
