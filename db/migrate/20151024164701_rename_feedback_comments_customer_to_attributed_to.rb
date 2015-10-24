class RenameFeedbackCommentsCustomerToAttributedTo < ActiveRecord::Migration
  def change
    rename_column :feedback_comments, :customer, :attributed_to
  end
end
