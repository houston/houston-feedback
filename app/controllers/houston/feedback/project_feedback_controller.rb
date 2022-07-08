require "csv"
require "charlock_holmes/string"

module Houston
  module Feedback
    class ProjectFeedbackController < Houston::Feedback::ApplicationController
      attr_reader :project, :conversations

      layout "houston/feedback/application"
      before_action :find_project

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

      COMMON_SURVEY_RESPONSES_TO_IGNORE = [
        "",
        "Yes",
        "No",
        "Very dissatisfied",
        "Somewhat dissatisfied",
        "Somewhat satisfied",
        "Very satisfied",
        "Very unlikely",
        "Somewhat unlikely",
        "Somewhat likely",
        "Very likely"
      ].freeze

      def index
        authorize! :read, Conversation

        @title = "Feedback • #{project.name}"
        @q = params.fetch(:q, "")
        @conversations = Conversation \
          .for_project(project)
          .with_flags_for(current_user)
          .search(@q, current_user)

        respond_to do |format|
          format.json do
            hashes = ConversationPresenter.new(current_ability, conversations).as_json
            json = Houston.benchmark("Encode JSON") { Oj.dump(hashes, mode: :compat) }
            render json: json
          end
          format.html do
            @projects = Project.unretired.with_feature(:feedback)
            @tags = Conversation.for_project(project).tags
            @customers = Customer.order(:name)
          end
          format.xlsx do
            send_data ConversationExcelPresenter.new(project, params[:q], conversations.preload(:user)),
              type: :xlsx,
              filename: "Feedback.xlsx",
              disposition: "attachment"
          end
        end
      end

      def create
        params[:attributed_to] = params[:attributedTo] if params.key?(:attributedTo)
        conversation = Conversation.new(params.permit(:attributed_to, :text, :tags))
        conversation.project = project
        conversation.user = current_user

        authorize! :create, conversation

        if conversation.save
          conversation.read_by! current_user
          render json: ConversationPresenter.new(current_ability, conversation)
        else
          render json: conversation.errors, status: :unprocessable_entity
        end
      end

      def upload_csv
        authorize! :create, Conversation

        @target = params[:target]

        dir = File.join(Houston::Application.paths["tmp"].first, "uploads")
        FileUtils.mkdir_p(dir)
        session[:csv_path] = File.join(dir, "#{Time.now.strftime("%Y%m%d%H%M%S")}.csv")
        FileUtils.mv params[:file].tempfile.path, session[:csv_path]

        begin
          csv = read_csv session[:csv_path]
        rescue ArgumentError
          @data = {
            ok: false,
            filename: params[:file].original_filename,
            error: $!.message }
          render layout: false
          return
        end

        headings = []
        Array(csv.shift).each_with_index do |heading, i|
          next if COMMON_SURVEY_FIELDS_TO_IGNORE.member?(heading)
          next if csv.all? { |row| COMMON_SURVEY_RESPONSES_TO_IGNORE.member?(row[i].to_s.strip) }
          example = csv.lazy.map { |row| row[i] }.find { |value| !value.blank? }
          headings.push(text: heading, index: i, example: example)
        end

        @data = {
          ok: true,
          filename: params[:file].original_filename,
          headings: headings,
          customerFields: session.fetch(:import_customer_fields, []) }
        render layout: false
      end

      def import
        authorize! :create, Conversation

        customer_fields = params.fetch(:customer_fields, []).map(&:to_i)
        feedback_fields = params.fetch(:feedback_fields, []).map(&:to_i)
        tags = params.fetch(:tags, [])

        import = SecureRandom.hex(16) # generates a 32-character string, naturally
        csv = read_csv session[:csv_path]
        conversations = []
        headings = csv.shift
        session[:import_customer_fields] = headings.values_at(*customer_fields)

        csv.each do |row|
          attributed_to = row.values_at(*customer_fields).map { |val| val.to_s.strip }.reject(&:blank?).join(", ")
          next if attributed_to.blank?

          text = []
          feedback_fields.each do |i|
            feedback, question = row[i].to_s.strip, headings[i]
            next if feedback.blank?
            text << "###### #{question}\n#{feedback}" unless question.blank?
          end

          if text.any?
            conversation = Conversation.new(
              import: import,
              project: project,
              user: current_user,
              attributed_to: attributed_to,
              text: text.join("\n\n"),
              tags: tags)
            conversation.update_plain_text # because the import command won't
            conversations.push(conversation)
          end
        end

        Houston.benchmark("[feedback:csv] import #{conversations.count} conversations") do
          Conversation.import conversations
        end

        Houston.benchmark("[feedback:csv] index conversations") do
          Conversation.for_project(project).reindex!
        end

        Houston.observer.fire "feedback:import", conversations: conversations

        render json: {count: conversations.count}
      end

      def history
        @title = "Feedback History"
        authorize! :read, Houston::Feedback::Version
        @changes = Houston::Feedback::Version
          .where(versioned_type: "Houston::Feedback::Conversation")
          .order(created_at: :desc)
          .includes(:user)
      end

      def from_email
        Rails.logger.warn params.inspect
      end

    private

      def find_project
        @project = Project.find_by_slug! params[:slug]
      end

      def read_csv(path)
        content = File.read(path)
        unless content.is_utf8?
          detection = CharlockHolmes::EncodingDetector.detect(content)
          content = CharlockHolmes::Converter.convert content, detection[:encoding], "UTF-8"
        end
        CSV.parse(content).to_a
      end

    end
  end
end
