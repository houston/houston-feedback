module Houston
  module Feedback
    class TagsController < ApplicationController
      attr_reader :conversations, :tags
      before_filter :find_conversations_and_tags


      def add
        authorize! :tag, Conversation

        conversations.find_each do |conversation|
          conversation.tags = conversation.tags | tags.map { |tag| tag.underscore.dasherize }
          conversation.updated_by = current_user
          conversation.save
        end
        head :ok
      end


      def remove
        authorize! :tag, Conversation

        conversations.find_each do |conversation|
          conversation.tags = conversation.tags - tags
          conversation.updated_by = current_user
          conversation.save
        end
        head :ok
      end


    private

      def find_conversations_and_tags
        @conversations = Conversation.where(id: params[:conversation_ids])
        @tags = Array(params[:tags])
      end

    end
  end
end
