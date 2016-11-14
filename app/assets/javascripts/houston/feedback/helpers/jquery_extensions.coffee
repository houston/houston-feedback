$.fn.extend

  between: (element0, element1)->
    $context = $(this)
    index0 = $context.index(element0)
    index1 = $context.index(element1)
    if index0 <= index1 then @slice(index0, index1 + 1) else @slice(index1, index0 + 1)

  autocompleteTags: (tags)->
    extractor = (query)->
      result = /([^,]+)$/.exec(query)
      if result and result[1] then result[1].trim().replace(/^#/, '') else ''

    $(@)
      .attr('autocomplete', 'off')
      .typeahead
        source: tags
        updater: (item)->
          @$element.val().replace(/[^,]*$/, ' ').replace(/^\s+/, '') + item + ', '
        matcher: (item)->
          tquery = extractor(@query)
          return false unless tquery
          ~item.toLowerCase().indexOf(tquery.toLowerCase())
        highlighter: (item)->
          query = extractor(@query).replace(/[\-\[\]{}()*+?.,\\\^$|#\s]/g, '\\$&')
          item.replace /(#{query})/ig, ($1, match)-> "<strong>#{match}</strong>"

  selectedTags: ->
    text = @.val()
    tags = _.reduce text.split(/[,;]/), (tags, tag) ->

      # Normalize tags
      tag = tag.trim().toLowerCase().replace(/^#/, '').replace(/[^\w\/\?]+/g, '-')

      # Convert "feature/subfeature" to ["feature", "feature-subfeature"]
      tags.concat _.reduce tag.split(/\//), (tags, tag)->
        tags.concat tags.slice(-1).concat(tag).join("-")
      , []
    , []
    _.reject tags, (tag)-> !tag
