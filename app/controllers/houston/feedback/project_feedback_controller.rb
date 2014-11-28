module Houston
  module Feedback
    class ProjectFeedbackController < ApplicationController
      layout "houston/feedback/application"
      
      def index
        @project = Project.find_by_slug! params[:slug]
        @comments = Houston::Feedback::CommentPresenter.new(
          Houston::Feedback::Comment \
            .for_project(@project)
            .includes(:user)
            .search(params[:q])) if params[:q]
        
        respond_to do |format|
          format.json { render json: @comments }
          format.html
        end
      end
      
    end
  end
end
