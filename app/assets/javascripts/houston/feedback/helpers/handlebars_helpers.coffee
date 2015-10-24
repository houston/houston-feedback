Handlebars.registerHelper 'tagUrl', (tag)->
  "?q=#{encodeURIComponent("##{tag}")}"

Handlebars.registerHelper 'renderComment', HandlebarsTemplates['houston/feedback/comments/show']
