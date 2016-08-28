class AddLegacyIdToFeedbackComments < ActiveRecord::Migration
  def change
    add_column :feedback_comments, :legacy_id, :string
    add_index :feedback_comments, :legacy_id, where: "legacy_id IS NOT NULL", unique: true
  end
end
