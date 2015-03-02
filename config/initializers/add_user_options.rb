Houston.config.add_user_option "feedback.digest" do
  name "Feedback"
  html do |f|
    <<-HTML
    <p class="notifications-instructions">
      for projects I follow, send me a digest of new feedback:
    </p>
    
    #{f.label("feedback.digest_never",  class: "radio") { f.radio_button(:"feedback.digest", "never")  + " Never" }}
    #{f.label("feedback.digest_daily",  class: "radio") { f.radio_button(:"feedback.digest", "daily")  + " Daily" }}
    #{f.label("feedback.digest_weekly", class: "radio") { f.radio_button(:"feedback.digest", "weekly") + " Weekly" }}
    HTML
  end
end
