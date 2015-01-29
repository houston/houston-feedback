module Houston
  module Feedback
    class TagsController < ApplicationController
      attr_reader :comments, :tags
      before_filter :find_comments_and_tags
      
      
      def add
        authorize! :tag, Comment
        
        comments.find_each do |comment|
          comment.tags = comment.tags | tags
          comment.updated_by = current_user
          comment.save
        end
        head :ok
      end
      
      
      def remove
        authorize! :tag, Comment
        
        comments.find_each do |comment|
          comment.tags = comment.tags - tags
          comment.updated_by = current_user
          comment.save
        end
        head :ok
      end
      
      
    private
      
      def find_comments_and_tags
        @comments = Comment.where(id: params[:comment_ids])
        @tags = Array(params[:tags]).map { |tag| tag.underscore.dasherize }
      end
      
    end
  end
end
