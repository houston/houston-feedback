module Houston
  module Feedback
    class CommentsController < ApplicationController

      def create
        comment_params = params.require(:comment).permit(:conversation_id, :text)
        conversation = Houston::Feedback::Conversation.find comment_params[:conversation_id]
        comment = conversation.comments.create(user: current_user, text: comment_params[:text])
        if comment.persisted?
          render json: Houston::Feedback::CommentPresenter.new(comment)
        else
          render json: comment.errors, status: :unprocessable_entity
        end
      end

      def update
        comment_params = params.require(:comment).permit(:text)
        comment = Houston::Feedback::Comment.find(params[:id])
        if comment.update_attributes(comment_params)
          render json: Houston::Feedback::CommentPresenter.new(comment)
        else
          render json: comment.errors, status: :unprocessable_entity
        end
      end

      def destroy
        comment = Houston::Feedback::Comment.find(params[:id])
        comment.destroy if comment
        render json: {}
      end

    end
  end
end
