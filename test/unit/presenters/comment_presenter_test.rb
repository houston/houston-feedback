require "test_helper"

class CommentPresenterTest < ActiveSupport::TestCase

  context "#optimized_present_all" do
    should "present the same content as #unoptimized_present_all" do
      ability = Class.new do
        def can?(*args)
          true
        end
      end.new

      user = User.first

      comments = [
        FactoryGirl.create(:comment),
        FactoryGirl.create(:comment),
        FactoryGirl.create(:comment)
      ]

      comments[1].read_by! user
      comments[2].set_signal_strength_by! user, 2

      presenter = Houston::Feedback::CommentPresenter.new(ability, :ignore)
      comments = Houston::Feedback::Comment.with_flags_for(user)

      expected_results = JSON.pretty_generate presenter.unoptimized_present_all(comments)
      actual_results = JSON.pretty_generate presenter.optimized_present_all(comments)
      assert_equal expected_results, actual_results
    end
  end

end
