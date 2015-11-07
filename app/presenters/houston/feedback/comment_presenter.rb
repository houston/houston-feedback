require "pluck_map/presenter"

module Houston
  module Feedback
    class CommentPresenter
      attr_reader :ability, :comments

      delegate :can?, to: :ability

      def initialize(ability, comments)
        @ability = ability
        @comments = OneOrMany.new(comments || [])
      end

      def as_json(*args)
        if comments.is_a?(ActiveRecord::Relation)
          return optimized_present_all(comments)
        end

        Houston.benchmark "[#{self.class.name.underscore}] Prepare JSON" do
          comments.map(&method(:comment_to_json))
        end
      end

      def optimized_present_all(comments)
        reporters = User.where(id: comments.reorder(nil).pluck("DISTINCT feedback_comments.user_id")).pluck(:id, :email, :first_name, :last_name).each_with_object({}) { |(id, email, first_name, last_name), map| map[id] = {
          id: id,
          name: "#{first_name} #{last_name}",
          firstName: first_name,
          email: email } }

        customers = Customer.where(id: comments.reorder(nil).pluck("DISTINCT feedback_comments.customer_id")).pluck(:id, :name).each_with_object({}) { |(id, name), map| map[id] = {
          id: id,
          slug: name.gsub(/\s+/, "").downcase,
          name: name } }

        comments.arel.projections
        excerpt = comments.arel.projections.detect { |fn| fn.is_a?(Arel::Nodes::NamedFunction) && fn.alias == "excerpt" }
        if excerpt
          excerpt.alias = nil
          excerpt = excerpt.to_sql
        end

        rank = comments.arel.projections.detect { |fn| fn.is_a?(Arel::Nodes::As) && fn.right == "rank" }
        rank = rank.left.to_sql if rank

        comment = Houston::Feedback::Comment.new

        PluckMap::Presenter.new do |q|
          q.id
          q.createdAt select: :created_at
          q.import
          q.reporter select: :user_id, map: ->(id) { reporters[id] }
          q.attributedTo select: :attributed_to
          q.customer select: :customer_id, map: ->(id) { customers[id] }
          q.text
          if excerpt
            q.excerpt select: excerpt
          else
            q.excerpt select: :text, map: ->(text) {
              lines = text.lines.map(&:strip).reject(&:blank?)
              lines.shift if lines.any? && lines[0].starts_with?("#####")
              lines.join[0..140] }
          end

          # HACK: This is uses the flyweight pattern to NOT instantiate
          # a Houston::Feedback::Comment for every result. However, we're
          # relying on special knowledge here that our-houston defines
          # abilities for comments like so:
          #
          # # Everyone can read and tag and create feedback
          # can :read, Houston::Feedback::Comment
          # can :tag, Houston::Feedback::Comment
          # can :create, Houston::Feedback::Comment
          #
          # # Everyone can update their own feedback
          # can [:update, :destroy], Houston::Feedback::Comment, user_id: user.id

          q.permissions select: [:user_id], map: ->(id) {
            comment.user_id = id
            { update: can?(:update, comment),
              destroy: can?(:destroy, comment) } }
          q.read select: "flags.read"
          q.rank select: rank if rank
          q.tags select: :tags, map: ->(tags) { tags.to_s.split("\n") }
        end.to_h(comments)
      end

      def comment_to_json(comment)
        { id: comment.id,
          createdAt: comment.created_at,
          import: comment.import,
          reporter: comment.user && {
            id: comment.user.id,
            name: comment.user.name,
            firstName: comment.user.first_name,
            email: comment.user.email },
          attributedTo: comment.attributed_to,
          customer: comment.customer && {
            id: comment.customer.id,
            slug: comment.customer.slug,
            name: comment.customer.name },
          text: comment.text,
          excerpt: comment.excerpt,
          permissions: {
            update: can?(:update, comment),
            destroy: can?(:destroy, comment) },
          read: comment[:read],
          rank: comment[:rank],
          tags: comment.tags }
      end

    end
  end
end
