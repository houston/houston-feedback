Handlebars.registerHelper 'tagUrl', (tag)->
  "?q=#{encodeURIComponent("##{tag}")}"

Handlebars.registerHelper 'renderFeedback', HandlebarsTemplates['houston/feedback/conversations/show']
Handlebars.registerHelper 'renderComment', HandlebarsTemplates['houston/feedback/comments/show']
Handlebars.registerHelper 'renderFeedbackCommands', HandlebarsTemplates['houston/feedback/conversations/commands']

Handlebars.registerHelper 'example', (example)->
  url = "#{window.location.pathname}?q=#{encodeURIComponent(example)}"
  """
  <a class="feedback-search-example" href="#{url}">#{example}</a>
  """

Handlebars.registerHelper 'signalStrengthImage', (value, context) ->
  value = +value
  value = 0 unless value >= 0 and value <= 4
  i = Math.round(value)
  img = "signal-strength-#{i}"
  size = context?.hash?.size ? 32

  """
  <img class="feedback-signal-strength" width="#{size}" height="#{size}" title="#{value.toFixed(2)}" src="#{App.Feedback.images[img]}" />
  """

Handlebars.registerHelper 'renderFeedbackTags', (tags) ->
  spans = for tag in tags
    """
      <span class="feedback-tag">
        #{tag}
        <a class="feedback-remove-tag"><i class="fa fa-close"></i></a>
      </span>
    """
  window.spans = spans
  spans.join("")

Handlebars.registerHelper 'renderFeedbackTagsReadonly', (tags) ->
  spans = for tag in tags
    """
      <span class="feedback-tag feedback-tag-readonly">#{tag}</span>
    """
  window.spans = spans
  spans.join("")
