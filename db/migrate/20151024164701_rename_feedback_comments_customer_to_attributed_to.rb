class RenameFeedbackCommentsCustomerToAttributedTo < ActiveRecord::Migration[4.2]
  def change
    rename_column :feedback_comments, :customer, :attributed_to
  end
end
