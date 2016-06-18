module Houston
  module Feedback
    class CommentsController < ApplicationController
      attr_reader :comments, :comment
      before_filter :find_comment, except: [:destroy, :move]
      before_filter :find_comments, only: [:destroy, :move]


      def show
        if unfurling?
          @author = comment.attributed_to
          if comment.user
            @author << " (#{comment.user.name})" unless @author.empty?
            @author = comment.user.name if @author.empty?
          end

          lines = comment.text.split(/\n/)

          # Replace H_ tags with bold text of the same font size
          # and get rid of inner quotes.
          lines = lines.map do |line|
            line.strip
              .gsub(/^#+\s*(.*)$/m, "*\\1*") # replace H_ tags with bold text
              .gsub(/^>\s*/m, "") # get rid of inner quotes
              .gsub(/\*{2}/, "*") # it takes only one * to bold things in Slack
              .gsub(/\!\[.*\]\(([^)]+)\)/, "\\1") # clean up images
          end
          @message = lines.join("\n").gsub(/\n+/m, "\n").strip

        else
          authorize! :read, comment
          redirect_to project_feedback_url(comment.project, q: "id:#{comment.id}")
        end
      end


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
        comment.read_by! current_user
        head :ok
      end


      def mark_unread
        comment.read_by! current_user, false
        head :ok
      end


      def signal_strength
        comment.set_signal_strength_by! current_user, params[:signal_strength]
        find_comment # reload
        render json: Houston::Feedback::CommentPresenter.new(current_ability, comment)
      end


    private

      def find_comment
        @comment = Comment.with_flags_for(current_user).find params[:id]
      end

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
