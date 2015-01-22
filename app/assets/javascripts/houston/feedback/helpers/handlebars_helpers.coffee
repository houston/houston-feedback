Handlebars.registerHelper 'tagUrl', (tag)->
  "?q=#{encodeURIComponent("##{tag}")}"
