module Houston
  module Feedback
    class CommentPresenter
      attr_reader :ability
      
      delegate :can?, to: :ability
      
      def initialize(ability, comments)
        @ability = ability
        @comments = OneOrMany.new(comments || [])
      end
      
      def as_json(*args)
        comments = @comments
        comments = Houston.benchmark "[#{self.class.name.underscore}] Load objects" do
          comments.load
        end if comments.is_a?(ActiveRecord::Relation)
        Houston.benchmark "[#{self.class.name.underscore}] Prepare JSON" do
          comments.map(&method(:comment_to_json))
        end
      end
      
      def comment_to_json(comment)
        { id: comment.id,
          createdAt: comment.created_at,
          import: comment.import,
          project: present_project(comment.project),
          reporter: present_reporter(comment.user),
          customer: comment.customer,
          text: comment.text,
          excerpt: comment.excerpt,
          permissions: {
            update: can?(:update, comment),
            destroy: can?(:destroy, comment) },
          read: comment[:read],
          rank: comment[:rank],
          tags: comment.tags }
      end
      
      def present_project(project)
        { slug: project.slug,
          color: project.color }
      end
      
      def present_reporter(user)
        { id: user.id,
          name: user.name,
          firstName: user.first_name,
          email: user.email } if user
      end
      
    end
  end
end