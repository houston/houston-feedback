require "test_helper"

class ConversationTest < ActiveSupport::TestCase
  attr_reader :feedback


  context "a new feedback" do
    should "convert rich-text to plain-text to be indexed and displayed in snippets" do
      feedback = Houston::Feedback::Conversation.create!(project_id: 1, text: "### Heading 3\n - One\n - Two\n")
      assert_equal "Heading 3\nOne\nTwo\n", feedback.plain_text
    end
  end


  context "set_signal_strength_by!" do
    setup do
      @feedback = Houston::Feedback::Conversation.create!(project_id: 1, text: "feedback text")
      @user1 = User.first
      @user2 = User.second
    end

    should "allow signal_strength to be nil" do
      feedback.set_signal_strength_by! @user1, nil
    end

    should "treat 0 as nil" do
      feedback.set_signal_strength_by! @user1, 0
      assert_equal nil, feedback.get_signal_strength_by(@user1)
    end

    should "allow signal_strength to be 1-4" do
      [1, 2, 3, 4].each do |value|
        feedback.set_signal_strength_by! @user1, value
        assert_equal value, feedback.get_signal_strength_by(@user1)
      end
    end

    should "raise a validation error if signal_strength is not 1-4" do
      [7, "nope"].each do |value|
        assert_raise ActiveRecord::RecordInvalid, "#{value.inspect} should be an invalid value for signal_strength" do
          feedback.set_signal_strength_by! @user1, value
        end
      end
    end

    should "cache the new average signal_strength on feedback" do
      feedback.set_signal_strength_by! @user1, 1
      assert_equal 1, feedback.reload.average_signal_strength

      feedback.set_signal_strength_by! @user2, 3
      assert_equal 2, feedback.reload.average_signal_strength

      feedback.set_signal_strength_by! @user1, nil
      assert_equal 3, feedback.reload.average_signal_strength

      feedback.set_signal_strength_by! @user2, nil
      assert_equal nil, feedback.reload.average_signal_strength
    end
  end

end
