require "test_helper"

class ConversationPresenterTest < ActiveSupport::TestCase

  context "#optimized_present_all" do
    should "present the same content as #unoptimized_present_all" do
      ability = Class.new do
        def can?(*args)
          true
        end
      end.new

      user = User.first

      conversations = [
        FactoryGirl.create(:conversation),
        FactoryGirl.create(:conversation),
        FactoryGirl.create(:conversation)
      ]

      conversations[1].read_by! user
      conversations[2].set_signal_strength_by! user, 2

      presenter = Houston::Feedback::ConversationPresenter.new(ability, :ignore)
      conversations = Houston::Feedback::Conversation.with_flags_for(user)

      expected_results = JSON.pretty_generate presenter.unoptimized_present_all(conversations)
      actual_results = JSON.pretty_generate presenter.optimized_present_all(conversations)
      assert_equal expected_results, actual_results
    end
  end

end
