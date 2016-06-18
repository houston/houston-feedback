require "test_helper"

class CommentTest < ActiveSupport::TestCase
  attr_reader :comment


  context "a new comment" do
    should "convert rich-text to plain-text to be indexed and displayed in snippets" do
      comment = Houston::Feedback::Comment.create!(project_id: 1, text: "### Heading 3\n - One\n - Two\n")
      assert_equal "Heading 3\nOne\nTwo\n", comment.plain_text
    end
  end


  context "set_signal_strength_by!" do
    setup do
      @comment = Houston::Feedback::Comment.create!(project_id: 1, text: "comment text")
      @user1 = User.first
      @user2 = User.second
    end

    should "allow signal_strength to be nil" do
      comment.set_signal_strength_by! @user1, nil
    end

    should "treat 0 as nil" do
      comment.set_signal_strength_by! @user1, 0
      assert_equal nil, comment.get_signal_strength_by(@user1)
    end

    should "allow signal_strength to be 1-4" do
      [1, 2, 3, 4].each do |value|
        comment.set_signal_strength_by! @user1, value
        assert_equal value, comment.get_signal_strength_by(@user1)
      end
    end

    should "raise a validation error if signal_strength is not 1-4" do
      [7, "nope"].each do |value|
        assert_raise ActiveRecord::RecordInvalid, "#{value.inspect} should be an invalid value for signal_strength" do
          comment.set_signal_strength_by! @user1, value
        end
      end
    end

    should "cache the new average signal_strength on comment" do
      comment.set_signal_strength_by! @user1, 1
      assert_equal 1, comment.reload.average_signal_strength

      comment.set_signal_strength_by! @user2, 3
      assert_equal 2, comment.reload.average_signal_strength

      comment.set_signal_strength_by! @user1, nil
      assert_equal 3, comment.reload.average_signal_strength

      comment.set_signal_strength_by! @user2, nil
      assert_equal nil, comment.reload.average_signal_strength
    end
  end

end
