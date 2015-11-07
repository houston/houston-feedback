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
        comments = Houston.benchmark "[#{self.class.name.underscore}] Load objects" do
          comments.includes(:user, :customer).load
        end if comments.is_a?(ActiveRecord::Relation)
        Houston.benchmark "[#{self.class.name.underscore}] Prepare JSON" do
          comments.map(&method(:comment_to_json))
        end
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
          archived: comment.archived?,
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
          averageSignalStrength: comment.average_signal_strength,
          signalStrength: comment[:signal_strength],
          read: comment[:read],
          rank: comment[:rank],
          tags: comment.tags }
      end

    end
  end
end
