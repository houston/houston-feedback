module Houston
  module Feedback
    class CommentPresenter
      attr_reader :comment

      def initialize(comment)
        @comment = comment
      end

      def as_json(*args)
        { id: comment.id,
          createdAt: comment.created_at,
          user: comment.user && {
            id: comment.user.id,
            name: comment.user.name,
            firstName: comment.user.first_name,
            email: comment.user.email },
          text: comment.text }
      end

    end
  end
end
