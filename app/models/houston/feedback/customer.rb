module Houston
  module Feedback
    class Customer < ActiveRecord::Base
      self.table_name = "feedback_customers"

      after_save :identify_customers

      def self.find_by_attributed_to(attributed_to)
        where(["? = ANY(attributions)", attributed_to]).first
      end

      def slug
        name.gsub(/\s+/, "").downcase
      end

      def add_attribution(attribution)
        return if attributions.member? attribution
        self.attributions = attributions + [attribution]
        save
      end

      def identify_customers
        return unless changed.member? "attributions"
        attributions_removed = Array(changes["attributions"][0]) - attributions
        attributions_added   = attributions - Array(changes["attributions"][0])

        Comment.where(attributed_to: attributions_removed, customer_id: id).update_all(customer_id: nil)
        Comment.where(attributed_to: attributions_added).update_all(customer_id: id)
      end

    end
  end
end
