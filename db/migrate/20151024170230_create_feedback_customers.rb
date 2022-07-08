class CreateFeedbackCustomers < ActiveRecord::Migration[4.2]
  def change
    create_table :feedback_customers do |t|
      t.string :name, null: false
      t.text :attributions, array: true
    end

    add_column :feedback_comments, :customer_id, :integer
  end
end
