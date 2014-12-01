require "test_helper"

class CommentTest < ActiveSupport::TestCase

  context "a new comment" do
    should "convert rich-text to plain-text to be indexed and displayed in snippets" do
      comment = Houston::Feedback::Comment.create!(project_id: 1, text: "### Heading 3\n - One\n - Two\n")
      assert_equal "Heading 3\nOne\nTwo\n", comment.plain_text
    end
  end

end
