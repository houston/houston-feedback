module Houston
  module Feedback
    class CommentsController < ApplicationController
      attr_reader :comments
      before_filter :find_comments, only: :destroy
      
      
      def destroy
        count = comments.length
        comments.delete_all
        render json: {count: count}
      end
      
      
      def mark_read
        comment = Comment.find params[:id]
        comment.read_by! current_user
        head :ok
      end
      
      
    private
      
      def find_comments
        if params.key? :comment_ids
          @comments = Comment.where(id: params[:comment_ids])
        elsif params.key? :import
          @comments = Comment.where(import: params[:import])
        else
          head 400
        end
      end
      
    end
  end
end
