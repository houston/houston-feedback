require "redcarpet/render_strip"

module Houston
  module Feedback
    class Comment < ActiveRecord::Base
      self.table_name = "feedback_comments"
      
      before_save :update_plain_text, :if => :text_changed?
      after_save :update_search_vector, :if => :search_vector_should_change?
      
      belongs_to :project
      belongs_to :user
      
      has_many :read_receipts, class_name: "Houston::Feedback::CommentReadReceipt"
      
      class << self
        def for_project(project)
          where(project_id: project.id)
        end
        
        def with_read_by(user)
          joins(<<-SQL).select("feedback_comments.*", '(read_receipts.user_id IS NOT NULL) "read"')
            LEFT OUTER JOIN feedback_comments_read_receipts \"read_receipts\"
            ON read_receipts.comment_id=feedback_comments.id AND read_receipts.user_id=#{user.id}
          SQL
        end
        
        # http://blog.lostpropertyhq.com/postgres-full-text-search-is-good-enough/
        def search(query)
          config = PgSearch::Configuration.new({against: "plain_text"}, self)
          normalizer = PgSearch::Normalizer.new(config)
          options = { dictionary: "english", tsvector_column: "search_vector" }
          query = PgSearch::Features::TSearch.new(query, options, config.columns, self, normalizer)
          
          excerpt = ts_headline(:plain_text, query,
            start_sel: "<em>",
            stop_sel: "</em>",
            max_words: 10,
            min_words: 6,
            fragment_delimiter: " ... ",
            max_fragments: 2)
          rank = query.rank
          rank.extend Arel::AliasPredication
          where(query.conditions)
            .select("feedback_comments.*", excerpt.as("excerpt"), rank.as("rank"))
            .order("rank DESC")
        end
        
        def reindex!
          update_all <<-SQL
            search_vector = setweight(to_tsvector('english', tags), 'A') || 
                            setweight(to_tsvector('english', plain_text), 'B') ||
                            setweight(to_tsvector('english', customer), 'B')
          SQL
        end
      end
      
      def tags=(array)
        super Array(array).sort.join("\n")
      end
      
      def tags
        super.to_s.split("\n")
      end
      
      def update_plain_text
        md = Redcarpet::Markdown.new(Redcarpet::Render::StripDown, space_after_headers: true)
        self.plain_text = md.render(text)
      end
      
      def read_by!(user)
        read_receipts.create!(user_id: user.id)
      rescue ActiveRecord::RecordNotUnique
        # race condition, OK
      end
      
    private
      
      # http://www.postgresql.org/docs/9.1/static/textsearch-controls.html#TEXTSEARCH-HEADLINE
      def self.ts_headline(column, query, options={})
        column = arel_table[column] if column.is_a?(Symbol)
        options = options.map { |(key, value)| "#{key.to_s.camelize}=#{value}" }.join(", ")
        tsquery = Arel.sql(query.send(:tsquery))
        Arel::Nodes::NamedFunction.new("ts_headline", [column, tsquery, options])
      end
      
      def search_vector_should_change?
        (changed & %w{tags plain_text customer}).any?
      end
      
      def update_search_vector
        self.class.where(id: id).reindex!
      end
      
    end
  end
end