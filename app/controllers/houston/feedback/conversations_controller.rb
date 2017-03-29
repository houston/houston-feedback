module Houston
  module Feedback
    class ConversationsController < ApplicationController
      attr_reader :conversations, :conversation
      before_action :find_conversation, except: [:destroy, :move]
      before_action :find_conversations, only: [:destroy, :move]


      def show
        if unfurling?
          @author = conversation.attributed_to
          if conversation.user
            @author << " (#{conversation.user.name})" unless @author.empty?
            @author = conversation.user.name if @author.empty?
          end

          lines = conversation.text.split(/\n/)

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
          authorize! :read, conversation
          redirect_to project_feedback_url(conversation.project, q: "id:#{conversation.id}")
        end
      end


      def destroy
        authorize! :destroy, Conversation
        ids = conversations.pluck(:id)
        conversations.delete_all
        render json: {ids: ids}
      end


      def move
        authorize! :update, Conversation
        ids = conversations.pluck(:id)
        conversations.each do |conversation|
          conversation.update_attribute :project_id, params[:project_id]
        end
        render json: {ids: ids}
      end


      def update
        authorize! :update, conversation

        conversation.text = params[:text]
        conversation.attributed_to = params[:attributedTo]
        conversation.updated_by = current_user
        conversation.archived = params[:archived]

        if conversation.save
          render json: Houston::Feedback::ConversationPresenter.new(current_ability, conversation)
        else
          render json: conversation.errors, status: :unprocessable_entity
        end
      end


      def mark_read
        conversation.read_by! current_user
        head :ok
      end


      def mark_unread
        conversation.read_by! current_user, false
        head :ok
      end


      def signal_strength
        conversation.set_signal_strength_by! current_user, params[:signal_strength]
        find_conversation # reload
        render json: Houston::Feedback::ConversationPresenter.new(current_ability, conversation)
      end


    private

      def find_conversation
        @conversation = Conversation.with_flags_for(current_user).find params[:id]
      end

      def find_conversations
        if params.key? :conversation_ids
          @conversations = Conversation.where(id: params[:conversation_ids])
        elsif params.key? :import
          @conversations = Conversation.where(import: params[:import])
        else
          head 400
        end
      end

    end
  end
end
