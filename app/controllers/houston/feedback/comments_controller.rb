module Houston
  module Feedback
    class CommentsController < ApplicationController
      attr_reader :comments
      before_filter :find_comments
      
      
      def destroy
        count = comments.length
        comments.delete_all
        render json: {count: count}
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
