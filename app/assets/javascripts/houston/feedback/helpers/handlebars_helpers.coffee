Handlebars.registerHelper 'tagUrl', (tag)->
  "?q=#{encodeURIComponent("##{tag}")}"

Handlebars.registerHelper 'renderComment', HandlebarsTemplates['houston/feedback/comments/show']

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
