class AddSignalStrengthToComments < ActiveRecord::Migration[4.2]
  def change
    add_column :feedback_comments, :average_signal_strength, :float, null: true
    add_column :feedback_comments_user_flags, :signal_strength, :float, null: true
  end
end
