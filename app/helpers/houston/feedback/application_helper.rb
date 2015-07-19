module Houston::Feedback
  module ApplicationHelper

    def describe_changes(changes)
      before_all = {}
      after_all = {}
      changes.each do |change|
        change.modifications.each do |key, (before, after)|
          before_all[key] = before unless before_all.key?(key)
          after_all[key] = after
        end
      end

      before_all.keys.map do |key|
        before = before_all[key]
        after = after_all[key]

        case key
        when "text" then "changed the text"
        when "customer" then "changed the customer"
        when "tags"
          before = before.split if before.is_a?(String)
          after = after.split if before.is_a?(String)
          added = (after - before).map { |tag| "<span class=\"feedback-tag\">#{tag}</span>" }
          removed = (before - after).map { |tag| "<span class=\"feedback-tag\">#{tag}</span>" }

          phrases = []
          phrases.push "added the #{added.length == 1 ? "tag" : "tags"} #{added.to_sentence}" if added.any?
          phrases.push "removed the #{removed.length == 1 ? "tag" : "tags"} #{removed.to_sentence}" if removed.any?
          phrases.join " and "
        end
      end.join("; ").html_safe
    end

  end
end
