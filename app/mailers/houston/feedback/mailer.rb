module Houston::Feedback
  class Mailer < ::ViewMailer
    self.stylesheets = stylesheets + %w{houston/feedback/feedback.scss}

    # helper Houston::Reports::ApplicationHelper


    def daily_digest_for(conversations, user, options={})
      @conversations = conversations.includes(:project, :user)

      mail(options.pick(:cc, :bcc).merge({
        to:       user,
        subject:  "Feedback, Daily Digest ⭑ #{Date.today.strftime("%b %-d, %Y")}",
        template: "houston/feedback/mailer/digest"
      }))
    end

    def weekly_digest_for(conversations, user, options={})
      @conversations = conversations.includes(:project, :user)

      mail(options.pick(:cc, :bcc).merge({
        to:       user,
        subject:  "Feedback, Weekly Digest ⭑ #{Date.today.strftime("%b %-d, %Y")}",
        template: "houston/feedback/mailer/digest"
      }))
    end


  end
end
