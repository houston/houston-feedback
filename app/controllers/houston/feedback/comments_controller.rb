module Houston
  module Feedback
    class CommentsController < ApplicationController
      attr_reader :comments
      before_filter :find_comments, only: [:destroy, :move]


      def destroy
        authorize! :destroy, Comment
        ids = comments.pluck(:id)
        comments.delete_all
        render json: {ids: ids}
      end


      def move
        authorize! :update, Comment
        ids = comments.pluck(:id)
        comments.update_all(project_id: params[:project_id])
        render json: {ids: ids}
      end


      def update
        comment = Comment.find(params[:id])
        authorize! :update, comment

        comment.text = params[:text]
        comment.attributed_to = params[:attributedTo]
        comment.updated_by = current_user

        if comment.save
          render json: Houston::Feedback::CommentPresenter.new(current_ability, comment)
        else
          render json: comment.errors, status: :unprocessable_entity
        end
      end


      def mark_read
        comment = Comment.find params[:id]
        comment.read_by! current_user
        head :ok
      end


      def mark_unread
        comment = Comment.find params[:id]
        comment.read_by! current_user, false
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
