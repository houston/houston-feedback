require "csv"

module Houston
  module Feedback
    class ProjectFeedbackController < ApplicationController
      attr_reader :project, :comments
      
      layout "houston/feedback/application"
      before_filter :find_project
      
      COMMON_SURVEY_FIELDS_TO_IGNORE = [
        "Time Started",
        "Date Submitted",
        "Status",
        "Language",
        "Referer",
        "Extended Referer",
        "SessionID",
        "User Agent",
        "Extended User Agent",
        "Longitude",
        "Latitude"
      ].freeze
      
      def index
        authorize! :read, Comment
        
        @q = params.fetch(:q, "-#no -#addressed -#invalid")
        @comments = Comment \
          .for_project(project)
          .includes(:user, :project)
          .with_flags_for(current_user)
          .search(@q)
        
        respond_to do |format|
          format.json do
            render json: CommentPresenter.new(current_ability, comments)
          end
          format.html do
            @tags_by_project = Comment.for_project(project).tags_by_project
          end
          format.xlsx do
            send_data CommentExcelPresenter.new(project, params[:q], comments),
              type: :xlsx,
              filename: "Comments.xlsx",
              disposition: "attachment"
          end
        end
      end
      
      def create
        comment = Comment.new(params.pick(:customer, :text, :tags))
        comment.project = project
        comment.user = current_user
        
        authorize! :create, comment
        
        if comment.save
          comment.read_by! current_user
          render json: CommentPresenter.new(current_ability, comment)
        else
          render json: comment.errors, status: :unprocessable_entity
        end
      end
      
      def upload_csv
        authorize! :create, Comment
        
        @target = params[:target]
        session[:csv_path] = params[:file].tempfile.path
        
        csv = CSV.open(session[:csv_path]).to_a
        headings = []
        csv.shift.each_with_index do |heading, i|
          next if COMMON_SURVEY_FIELDS_TO_IGNORE.member?(heading)
          next if csv.all? { |row| row[i].blank? }
          example = csv.lazy.map { |row| row[i] }.find { |value| !value.blank? }
          headings.push(text: heading, index: i, example: example)
        end
        
        @data = {
          headings: headings,
          filename: params[:file].original_filename }
        render layout: false
      end
      
      def import
        authorize! :create, Comment
        
        customer_fields = params.fetch(:customer_fields, []).map(&:to_i)
        feedback_fields = params.fetch(:feedback_fields, []).map(&:to_i)
        
        import = SecureRandom.hex(16) # generates a 32-character string, naturally
        csv = CSV.open(session[:csv_path]).to_a
        comments = []
        csv.shift
        csv.each do |row|
          customer = row.values_at(*customer_fields).reject(&:blank?).join(", ")
          row.values_at(*feedback_fields).each do |feedback|
            next if feedback.blank?
            comment = Comment.new(
              import: import,
              project: project,
              user: current_user,
              customer: customer,
              text: feedback)
            comment.update_plain_text # because the import command won't
            comments.push(comment)
          end
        end
        
        Houston.benchmark("[feedback:csv] import #{comments.count} comments") do
          Comment.import comments
        end
        
        Houston.benchmark("[feedback:csv] index comments") do
          Comment.for_project(project).reindex!
        end
        
        render json: {count: comments.count}
      end
      
      def from_email
        Rails.logger.warn params.inspect
      end
      
    private
      
      def find_project
        @project = Project.find_by_slug! params[:slug]
      end
      
    end
  end
end
