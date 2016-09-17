module Houston
  module Feedback
    class Snippet < ActiveRecord::Base
      self.table_name = "feedback_snippets"

      belongs_to :conversation, class_name: "::Houston::Feedback::Conversation"

      after_save :update_search_vector, :if => :search_vector_should_change?

      class << self
        def reindex!
          connection.update <<-SQL
            UPDATE feedback_snippets
              SET search_vector = setweight(to_tsvector('english', feedback_conversations.tags), 'A') ||
                                  setweight(to_tsvector('english', feedback_snippets.tags), 'A') ||
                                  setweight(to_tsvector('english', feedback_snippets.text), 'B') ||
                                  setweight(to_tsvector('english', feedback_conversations.attributed_to), 'B')
              FROM feedback_conversations
              WHERE feedback_snippets.conversation_id=feedback_conversations.id
              AND feedback_snippets.id IN (#{except(:select).select(:id).to_sql});
          SQL
        end
      end

      def tags=(array)
        super Array(array).uniq.sort.join("\n")
      end

      def tags
        super.to_s.split("\n")
      end

    private

      def search_vector_should_change?
        (changed & %w{tags text}).any?
      end

      def update_search_vector
        self.class.where(id: id).reindex!
      end

    end
  end
end
