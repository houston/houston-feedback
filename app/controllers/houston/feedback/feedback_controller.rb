module Houston
  module Feedback
    class FeedbackController < ApplicationController
      attr_reader :comments
      
      layout "houston/feedback/application"
      
      def index
        authorize! :read, Comment
        
        @q = params.fetch(:q, "-#no -#addressed -#invalid")
        @comments = Comment \
          .includes(:user, :project)
          .with_flags_for(current_user)
          .search(@q)
        
        respond_to do |format|
          format.json do
            render json: CommentPresenter.new(current_ability, comments)
          end
          format.html do
            @tags_by_project = Comment.tags_by_project
          end
        end
      end
      
    end
  end
end
