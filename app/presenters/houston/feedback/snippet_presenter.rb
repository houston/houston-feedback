module Houston
  module Feedback
    class SnippetPresenter
      attr_reader :snippet

      def initialize(snippet)
        @snippet = snippet
      end

      def as_json(*args)
        { id: snippet.id,
          tags: snippet.tags,
          highlight: { start: snippet.range[0], end: snippet.range[1] } }
      end

    end
  end
end
