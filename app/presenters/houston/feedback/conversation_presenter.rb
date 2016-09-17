require "pluck_map/presenter"

module Houston
  module Feedback
    class ConversationPresenter
      attr_reader :ability, :conversations

      delegate :can?, to: :ability

      def initialize(ability, conversations)
        @ability = ability
        @conversations = OneOrMany.new(conversations || [])
      end

      def as_json(*args)
        if conversations.is_a?(ActiveRecord::Relation)
          optimized_present_all(conversations)
        else
          unoptimized_present_all(conversations)
        end
      end

      def optimized_present_all(conversations)
        reporters = User.all.pluck(:id, :email, :first_name, :last_name).each_with_object({}) { |(id, email, first_name, last_name), map| map[id] = {
          id: id,
          name: "#{first_name} #{last_name}",
          firstName: first_name,
          email: email } }

        customers = Customer.where(id: conversations.reorder(nil).pluck("DISTINCT feedback_conversations.customer_id")).pluck(:id, :name).each_with_object({}) { |(id, name), map| map[id] = {
          id: id,
          slug: name.gsub(/\s+/, "").downcase,
          name: name } }

        conversation_ids = conversations.reorder(nil).pluck("DISTINCT feedback_conversations.id")

        comments = Comment.where(conversation_id: conversation_ids).pluck(:id, :created_at, :conversation_id, :user_id, :text).each_with_object(Hash.new { |hash, key| hash[key] = [] }) { |(id, created_at, conversation_id, user_id, text), map| map[conversation_id].push(
          id: id,
          createdAt: created_at,
          user: reporters[user_id],
          text: text) }

        snippets = Snippet.where.not(range: nil).where(conversation_id: conversation_ids).pluck(:conversation_id, :id, :tags, :range).each_with_object(Hash.new { |hash, key| hash[key] = [] }) { |(conversation_id, id, tags, range), map| map[conversation_id].push(
          id: id,
          tags: tags.to_s.split("\n"),
          highlight: { start: range[0], end: range[1] } ) }

        conversations.arel.projections
        excerpt = conversations.arel.projections.detect { |fn| fn.is_a?(Arel::Nodes::NamedFunction) && fn.alias == "excerpt" }
        if excerpt
          excerpt.alias = nil
          excerpt = excerpt.to_sql
        end

        rank = conversations.arel.projections.detect { |fn| fn.is_a?(Arel::Nodes::As) && fn.right == "rank" }
        rank = rank.left.to_sql if rank

        conversation = Houston::Feedback::Conversation.new

        PluckMap::Presenter.new do |q|
          q.id
          q.createdAt select: :created_at
          q.import
          q.reporter select: :user_id, map: ->(id) { reporters[id] }
          q.archived
          q.attributedTo select: :attributed_to
          q.customer select: :customer_id, map: ->(id) { customers[id] }
          q.text
          if excerpt
            q.excerpt select: excerpt
          else
            q.excerpt select: :text, map: ->(text) do
              lines = text.lines.map(&:strip).reject(&:blank?)
              lines.shift if lines.any? && lines[0].starts_with?("#####")
              lines.join[0..140]
            end
          end

          # We need to pass instances of Houston::Feedback::Conversation to `can?`
          # in order to present the current user's permissions.
          #
          # This is uses the flyweight pattern to avoid instantiating
          # a Houston::Feedback::Conversation for every result. However, we're
          # assuming that abilities will only care about the conversation's
          # author or project.
          q.permissions select: [:user_id, :project_id], map: ->(user_id, project_id) do
            conversation.user_id = user_id
            conversation.project_id = project_id
            { update: can?(:update, conversation),
              destroy: can?(:destroy, conversation),
              addComment: can?(:comment_on, conversation) }
          end

          q.averageSignalStrength select: :average_signal_strength
          q.signalStrength select: "flags.signal_strength"
          q.read select: "flags.read"
          q.rank select: rank ? rank : "NULL"
          q.tags select: :tags, map: ->(tags) { tags.to_s.split("\n") }

          q.comments select: :id, map: ->(id) { comments[id] }
          q.snippets select: :id, map: ->(id) { snippets[id] }
        end.to_h(conversations)
      end

      def unoptimized_present_all(conversations)
        Houston.benchmark "[#{self.class.name.underscore}] Prepare JSON" do
          conversations.map(&method(:conversation_to_json))
        end
      end

      def conversation_to_json(conversation)
        { id: conversation.id,
          createdAt: conversation.created_at,
          import: conversation.import,
          reporter: conversation.user && {
            id: conversation.user.id,
            name: conversation.user.name,
            firstName: conversation.user.first_name,
            email: conversation.user.email },
          archived: conversation.archived?,
          attributedTo: conversation.attributed_to,
          customer: conversation.customer && {
            id: conversation.customer.id,
            slug: conversation.customer.slug,
            name: conversation.customer.name },
          text: conversation.text,
          excerpt: conversation.excerpt,
          permissions: {
            update: can?(:update, conversation),
            destroy: can?(:destroy, conversation),
            addComment: can?(:comment_on, conversation) },
          averageSignalStrength: conversation.average_signal_strength,
          signalStrength: conversation[:signal_strength],
          read: conversation[:read],
          rank: conversation[:rank],
          tags: conversation.tags,
          comments: conversation.comments.map { |comment|
            Houston::Feedback::CommentPresenter.new(comment).as_json },
          snippets: conversation.snippets.where.not(range: nil).map { |snippet|
            Houston::Feedback::SnippetPresenter.new(snippet).as_json } }
      end

    end
  end
end
