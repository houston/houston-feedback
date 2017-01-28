require "redcarpet/render_strip"

module Houston
  module Feedback
    class Conversation < ActiveRecord::Base
      include Houston::Props

      self.table_name = "feedback_conversations"

      before_save :update_plain_text, :if => :text_changed?
      before_save :update_customer, :if => :attributed_to_changed?
      after_save :update_search_vector, :if => :search_vector_should_change?
      after_save :reset_snippets, :if => :text_changed?
      after_create { Houston.observer.fire "feedback:create", conversation: self }
      after_create { Houston.observer.fire "feedback:add", conversation: self }
      after_update(if: :project_id_changed?) { Houston.observer.fire "feedback:add", conversation: self }

      belongs_to :project
      belongs_to :user

      has_many :user_flags, class_name: "Houston::Feedback::ConversationUserFlags"
      belongs_to :customer, class_name: "Houston::Feedback::Customer"
      has_many :comments, class_name: "Houston::Feedback::Comment"
      has_many :snippets, class_name: "Houston::Feedback::Snippet"

      versioned only: [:attributed_to, :text, :tags]

      validates :attributed_to, length: { maximum: 255 }, allow_blank: true

      class << self
        def for_project(project)
          where(project_id: project.id)
        end

        def with_flags_for(user)
          return all unless user.respond_to?(:id)
          joins(<<-SQL).select("feedback_conversations.*", "flags.read", "flags.signal_strength")
            LEFT OUTER JOIN feedback_user_flags \"flags\"
            ON flags.conversation_id=feedback_conversations.id AND flags.user_id=#{user.id}
          SQL
        end

        def unread_by(user)
          with_flags_for(user).where("flags.read IS FALSE OR flags.read IS NULL")
        end

        def since(time)
          where arel_table[:created_at].gteq(time)
        end

        # http://blog.lostpropertyhq.com/postgres-full-text-search-is-good-enough/
        def search(query_string, current_user=nil)
          tags = []
          not_tags = []
          flags = []
          reporter_id = nil
          customer_ids = nil
          ids = []
          created_at = nil
          query_string = query_string
            .gsub(/\/(read|unread|untagged|imported|unimported|all|archived)/) { flags << $1; "" }
            .gsub(/\-\#([a-z\-\?0-9\|]+)/) { not_tags << $1; "" }
            .gsub(/\#([a-z\-\?0-9\|]+)/) { tags << $1; "" }
            .gsub(/\bby:me\b/) {
              if current_user
                reporter_id = current_user.id
                ""
              else
                "by:me"
              end }
            .gsub(/\bby:([A-Za-z0-9]+)\b/) {
              reporter_id = User.where(["lower(concat(first_name, last_name)) = ?", $1])
                .limit(1).pluck(:id)[0] || reporter_id
              "" }
            .gsub(/customer:([A-Za-z0-9]+)/) {
              customer_ids = Houston::Feedback::Customer.where(["lower(regexp_replace(name, '\\s+', '', 'g')) = ?", $1]).pluck(:id)
              customer_ids = [0] if customer_ids.none?
              "" }
            .gsub(/added:(\d{8}?)\.\.(\d{8}?)/) {
              min, max = $1, $2
              min = "20000101" if min.blank?
              max = "20991231" if max.blank?
              min = Date.strptime(min, "%Y%m%d").beginning_of_day
              max = Date.strptime(max, "%Y%m%d").end_of_day
              created_at = min..max
              "" }
            .gsub(/added:today/) {
              min = Date.today.beginning_of_day
              max = Date.today.end_of_day
              created_at = min..max
              "" }
            .gsub(/added:(\d{8})/) {
              date = Date.strptime($1, "%Y%m%d")
              min = date.beginning_of_day
              max = date.end_of_day
              created_at = min..max
              "" }
            .gsub(/id:(\d+)/) {
              ids << $1.to_i
              "" }
            .strip

          config = PgSearch::Configuration.new({against: "text"}, Houston::Feedback::Snippet)
          normalizer = PgSearch::Normalizer.new(config)
          options = { dictionary: "english", tsvector_column: "search_vector" }
          query = PgSearch::Features::TSearch.new(query_string, options, config.columns, Houston::Feedback::Snippet, normalizer)

          excerpt = ts_headline(:plain_text, query,
            start_sel: "<em>",
            stop_sel: "</em>",
            max_words: 10,
            min_words: 6,
            fragment_delimiter: " ... ",
            max_fragments: 2)
          rank = query.rank
          rank.extend Arel::AliasPredication

          results = joins(:snippets)

          if ids.any? or flags.member? "all"
            # nothing
          elsif flags.member? "archived"
            results = results.where(archived: true)
          else
            results = results.where(archived: false)
          end

          results = results.where("flags.read IS TRUE") if flags.member? "read"
          results = results.where("flags.read IS FALSE OR flags.read IS NULL") if flags.member? "unread"
          results = results.where("concat(feedback_conversations.tags, E'\\n', feedback_snippets.tags)='' OR concat(feedback_conversations.tags, E'\\n', feedback_snippets.tags)='converted'") if flags.member? "untagged"
          results = results.where.not(import: nil) if flags.member? "imported"
          results = results.where(import: nil) if flags.member? "unimported"

          # TODO: query on snippet tags too
          results = tags.inject(results) { |results, tag|
            results.where(["concat(feedback_conversations.tags, E'\\n', feedback_snippets.tags) ~ ?", "(?n)^(#{tag.gsub("?", "\\?")})$"]) } # (?n) specified the newline-sensitive option
          results = not_tags.inject(results) { |results, tag|
            results.where(["concat(feedback_conversations.tags, E'\\n', feedback_snippets.tags) !~ ?", "(?n)^(#{tag.gsub("?", "\\?")})$"]) } # (?n) specified the newline-sensitive option

          results = results.where(id: ids) if ids.any?
          results = results.where(user_id: reporter_id) if reporter_id
          results = results.where(customer_id: customer_ids) if customer_ids
          results = results.where(created_at: created_at) if created_at

          results = results.where(query.conditions)
            .select("feedback_conversations.*", excerpt.as("excerpt"), rank.as("rank"))
            .order("rank DESC") unless query_string.blank?
          results
        end

        def reindex!
          Houston::Feedback::Snippet.where(conversation_id: select(:id)).reindex!
        end

        def cache_average_signal_strength!
          update_all <<-SQL
            average_signal_strength = (SELECT AVG(feedback_user_flags.signal_strength) FROM feedback_user_flags WHERE feedback_user_flags.signal_strength IS NOT NULL AND feedback_user_flags.conversation_id=feedback_conversations.id)
          SQL
        end

        def tags
          left_outer_joins(:snippets).pluck("regexp_split_to_table(concat(feedback_conversations.tags, E'\\n', feedback_snippets.tags), '\\n')")
            .reject(&:blank?)
            .each_with_object(Hash.new(0)) { |tag, counter| counter[tag] += 1 }
            .sort_by { |tag, count| -count }
            .map { |tag, _| tag }
        end
      end

      def tags=(array)
        super Array(array).uniq.sort.join("\n")
      end

      def tags
        super.to_s.split("\n")
      end

      def update_plain_text
        md = Redcarpet::Markdown.new(Redcarpet::Render::StripDown, space_after_headers: true)
        self.plain_text = md.render(text)
      end

      def excerpt
        self[:excerpt] || begin
          lines = text.lines.map(&:strip).reject(&:blank?)
          lines.shift if lines.any? && lines[0].starts_with?("#####")
          lines.join[0..140]
        end
      end

      def read_by!(user, read=true)
        flags = user_flags.where(user_id: user.id).first_or_create
        flags.read = read
        flags.save!
      rescue ActiveRecord::RecordNotUnique
        # race condition, OK
      end

      def set_signal_strength_by!(user, value)
        value = nil if value == 0 or value == "0"
        flags = user_flags.where(user_id: user.id).first_or_create
        flags.signal_strength = value
        flags.save!
      rescue ActiveRecord::RecordNotUnique
        # race condition, OK
      end

      def get_signal_strength_by(user)
        user_flags.where(user_id: user.id).pluck(:signal_strength).first
      end

      def cache_average_signal_strength!
        self.class.where(id: id).cache_average_signal_strength!
      end

    private

      # http://www.postgresql.org/docs/9.1/static/textsearch-controls.html#TEXTSEARCH-HEADLINE
      def self.ts_headline(column, query, options={})
        column = arel_table[column] if column.is_a?(Symbol)
        options = options.map { |(key, value)| "#{key.to_s.camelize}=#{value}" }.join(", ")
        tsquery = Arel.sql(query.send(:tsquery))
        Arel::Nodes::NamedFunction.new("ts_headline", [column, Arel::Nodes.build_quoted(tsquery), Arel::Nodes.build_quoted(options)])
      end

      def search_vector_should_change?
        (changed & %w{tags plain_text attributed_to}).any?
      end

      def update_search_vector
        self.class.where(id: id).reindex!
      end

      def update_customer
        self.customer = Customer.find_by_attributed_to attributed_to
      end

      def reset_snippets
        snippets.where.not(range: nil).delete_all
      end

    end
  end
end
