module Houston::Feedback
  module ApplicationHelper

    def example(q)
      link_to q, {q: q}, {class: "feedback-search-example"}
    end

    def textual_changes(changes)
      before_all = {}
      after_all = {}
      changes.each do |change|
        change.modifications.each do |key, (before, after)|
          before_all[key] = before unless before_all.key?(key)
          after_all[key] = after
        end
      end

      before_all.keys.each_with_object([]) do |key, textual_changes|
        before = before_all[key]
        after = after_all[key]

        case key
        when "text"
          textual_changes.push "changed the text"
        when "customer"
          textual_changes.push "changed the customer"
        when "tags"
          before = before.split if before.is_a?(String)
          after = after.split if before.is_a?(String)
          added = (after - before).map { |tag| "<span class=\"feedback-tag\">#{tag}</span>" }
          removed = (before - after).map { |tag| "<span class=\"feedback-tag\">#{tag}</span>" }

          phrases = []
          phrases.push "added the #{added.length == 1 ? "tag" : "tags"} #{added.to_sentence}" if added.any?
          phrases.push "removed the #{removed.length == 1 ? "tag" : "tags"} #{removed.to_sentence}" if removed.any?
          textual_changes.push phrases.join(" and ") if phrases.any?
        end
      end
    end

  end
end
