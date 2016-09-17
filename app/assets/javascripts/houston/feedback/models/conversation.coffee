class Houston.Feedback.Conversation extends Backbone.Model
  urlRoot: '/feedback/conversations'

  addTags: (tags)->
    @set 'tags', _.union(@get('tags'), tags).sort(), silent: true

  removeTags: (tags)->
    @set 'tags', _.difference(@get('tags'), tags).sort(), silent: true

  isUnread: ->
    !@get 'read'

  markAsRead: (success)->
    $.post("#{@url()}/read").success =>
      @set 'read', true
      success()

  markAsUnread: (success)->
    $.post("#{@url()}/unread").success =>
      @set 'read', false
      success()

  archive: ->
    @save archived: true

  unarchive: ->
    @save archived: false

  setSignalStrength: (i, success)->
    $.put("#{@url()}/signal_strength", signal_strength: i).success (data) =>
      @set
        signalStrength: data.signalStrength
        averageSignalStrength: data.averageSignalStrength
      success()

  deleteComment: (id)->
    id = +id
    deferred = jQuery.Deferred()
    $.destroy "/feedback/comments/#{id}"
      .success =>
        i = _.findIndex @get('comments'), (comment)-> comment.id is id
        @get('comments').splice(i, 0)
        deferred.resolve()
      .error (response)->
        deferred.reject Errors.fromResponse(response)
    deferred.promise()

  createComment: (text)->
    deferred = jQuery.Deferred()
    $.post "/feedback/comments", comment: {conversation_id: @id, text: text}
      .success (comment)=>
        @get('comments').unshift(comment)
        deferred.resolve(comment)
      .error (response)->
        deferred.reject Errors.fromResponse(response)
    deferred.promise()

  updateComment: (id, text)->
    id = +id
    deferred = jQuery.Deferred()
    $.put "/feedback/comments/#{id}", comment: {text: text}
      .success (comment)=>
        i = _.findIndex @get('comments'), (comment)-> comment.id is id
        @get('comments')[i] = comment
        deferred.resolve(comment)
      .error (response)->
        deferred.reject Errors.fromResponse(response)
    deferred.promise()


  findComment: (id)->
    _.detect @get("comments"), (comment)-> comment.id == +id



  snippets: ->
    [{}].concat @get('snippets')

  addSnippet: (snippet) ->
    deferred = jQuery.Deferred()
    $.post "/feedback/conversations/#{@id}/snippets", snippet: snippet
      .success (snippet)=>
        index = @get('snippets').push(snippet)
        deferred.resolve(index)
      .error (response)->
        deferred.reject Errors.fromResponse(response)
    deferred.promise()

  addTagsToSnippet: (tags, i) ->
    deferred = jQuery.Deferred()
    if snippet = @get('snippets')[i - 1]
      tags = snippet.tags.concat(tags)
      $.put "/feedback/conversations/#{@id}/snippets/#{snippet.id}", snippet: {tags: tags}
        .success =>
          snippet.tags = tags
          deferred.resolve(snippet)
        .error (response)->
          deferred.reject Errors.fromResponse(response)
    else
      deferred.reject()
    deferred.promise()

  removeTagsFromSnippet: (tags, i) ->
    deferred = jQuery.Deferred()
    if snippet = @get('snippets')[i - 1]
      tags = _.without(snippet.tags, tags...)
      $.put "/feedback/conversations/#{@id}/snippets/#{snippet.id}", snippet: {tags: tags}
        .success =>
          snippet.tags = tags
          deferred.resolve(snippet)
        .error (response)->
          deferred.reject Errors.fromResponse(response)
    else
      deferred.reject()
    deferred.promise()

  deleteSnippet: (i) ->
    deferred = jQuery.Deferred()
    if snippet = @get('snippets')[i - 1]
      $.destroy "/feedback/conversations/#{@id}/snippets/#{snippet.id}"
        .success =>
          @get('snippets').splice(i - 1, 1)
          deferred.resolve()
        .error (response)->
          deferred.reject Errors.fromResponse(response)
    else
      deferred.reject()
    deferred.promise()


  attribution: ->
    (@get("customer")?.name or @get("attributedTo") or @get("reporter")?.name or "").trim()

  text: ->
    lines = @get("text").match(/^.*$/gm)

    # Replace H_ tags with bold text of the same font size
    # and get rid of inner quotes.
    lines = for line in lines
      line.trim()
        .replace /^#+\s*(.*)$/mg, "*$1*"
        .replace /^>\s*/mg, ""
    lines.push "    — #{@get("attributedTo") || @get("reporter")?.name}"
    lines.map((line)-> "> #{line}").join("\n")
      .replace /> \n> \n/mg, "> \n"
      .replace /^(> \*.*\*\n)> \n(?!> \*)/mg, "$1"

  html: ->
    lines = @get("text").match(/^.*$/gm)

    # Replace H_ tags with bold text of the same font size
    # and get rid of inner quotes.
    lines = for line in lines
      line.trim()
        .replace /^#+\s*(.*)$/mg, "**$1**\n"
        .replace /^>\s*/mg, ""

    """
    <p style="margin: 0; padding: 0;">&nbsp;</p>
    <div style="font-family: 'Helvetica Neue', roboto, Helvetica, Arial, sans-serif; padding: 1em;">
      <h3 style="font-weight: normal; font-size: 1.25em; line-height: 1em; padding: 0; margin: 0;">#{@get("attributedTo") || @get("reporter")?.name}</h3>
      <div style="font-size: 0.92em; line-height: 1em; padding: 0; margin: 0; color: #888;">#{@get("reporter")?.name} • #{Handlebars.helpers.formatDateWithYear2 @get("createdAt")}</div>
      <div style="border-left: 5px solid #ddd; padding-left: 0.66em; margin: 0;">#{App.mdown(lines.join("\n"))}</div>
    </div>
    <p style="margin: 0; padding: 0;">&nbsp;</p>
    """



class Houston.Feedback.Conversations extends Backbone.Collection
  model: Houston.Feedback.Conversation

  countTags: ->
    countByTag = {}
    for conversation in @models
      for tag in conversation.get('tags')
        countByTag[tag] = (countByTag[tag] ? 0) + 1
    _.sortBy ({tag: tag, count: count} for tag, count of countByTag), (n)-> -n.count
