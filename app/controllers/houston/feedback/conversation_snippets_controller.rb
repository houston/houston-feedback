module Houston
  module Feedback
    class ConversationSnippetsController < ApplicationController
      attr_reader :conversation, :snippet
      before_filter :find_conversation
      before_filter :find_snippet, only: [:update, :destroy]


      def create
        snippet = conversation.snippets.create(create_params)
        if snippet.persisted?
          render json: Houston::Feedback::SnippetPresenter.new(snippet)
        else
          render json: snippet.errors, status: :unprocessable_entity
        end
      end


      def update
        if snippet.update_attributes(update_params)
          render json: Houston::Feedback::SnippetPresenter.new(snippet)
        else
          render json: snippet.errors, status: :unprocessable_entity
        end
      end


      def destroy
        snippet.destroy
        render json: {}
      end


    private

      def find_conversation
        @conversation = Conversation.find params[:conversation_id]
      end

      def find_snippet
        @snippet = conversation.snippets.find params[:id]
      end

      def create_params
        params.require(:snippet).permit(:text, range: [], tags: [])
      end

      def update_params
        params.fetch(:snippet, {}).permit(tags: []).reverse_merge(tags: [])
      end

    end
  end
end
