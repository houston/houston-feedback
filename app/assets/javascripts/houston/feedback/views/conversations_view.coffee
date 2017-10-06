KEY =
  DELETE: 8
  TAB: 9
  RETURN: 13
  ESC: 27
  UP: 38
  DOWN: 40

MAX_TAGS = 8

class Houston.Feedback.ConversationsView extends Backbone.View
  template: HandlebarsTemplates['houston/feedback/conversations/index']
  renderFeedback: HandlebarsTemplates['houston/feedback/conversations/show']
  renderEditConversation: HandlebarsTemplates['houston/feedback/conversations/edit']
  renderNewConversation: HandlebarsTemplates['houston/feedback/conversations/new']
  renderEditMultiple: HandlebarsTemplates['houston/feedback/conversations/edit_multiple']
  renderSearchReport: HandlebarsTemplates['houston/feedback/conversations/report']
  renderImportModal: HandlebarsTemplates['houston/feedback/conversations/import']
  renderConfirmDeleteModal: HandlebarsTemplates['houston/feedback/conversations/confirm_delete']
  renderConfirmResetSnippetsModal: HandlebarsTemplates['houston/feedback/conversations/confirm_reset']
  renderDeleteImportedModal: HandlebarsTemplates['houston/feedback/conversations/delete_imported']
  renderChangeProjectModal: HandlebarsTemplates['houston/feedback/conversations/change_project']
  renderIdentifyCustomerModal: HandlebarsTemplates['houston/feedback/conversations/identify_customer']
  renderTagCloud: HandlebarsTemplates['houston/feedback/conversations/tags']
  renderFeedbackCommands: HandlebarsTemplates['houston/feedback/conversations/commands']
  renderSearchInstructions: HandlebarsTemplates['houston/feedback/search_instructions']
  renderEditComment: HandlebarsTemplates['houston/feedback/comments/edit']

  events:
    'submit #search_feedback': 'submitSearch'
    'change #sort_feedback': 'sort'
    'click #feedback_search_reset': 'resetSearch'
    'focus .feedback-search-result': 'resultFocused'
    'mousedown .feedback-search-result': 'resultClicked'
    'mouseup .feedback-search-result': 'resultReleased'
    'keydown': 'keydown'
    'keydown #q': 'keydownSearch'
    'focus #q': 'onFocusSearch'
    'click .feedback-conversation-close': 'selectNone'
    'click .feedback-conversation-copy-url': 'copyUrl'
    'click .feedback-remove-tag': 'removeTag'
    'keydown .feedback-new-tag': 'keydownNewTag'
    'click .btn-delete-conversation': 'deleteConversations'
    'click .btn-delete-snippet': 'deleteSnippet'
    'click .btn-move': 'moveConversations'
    'click .btn-edit': 'editConversationText'
    'click .btn-save': 'saveConversationText'
    'click .btn-archive': 'archiveConversation'
    'click .btn-unarchive': 'unarchiveConversation'
    'keydown .feedback-text textarea': 'keydownConversationText'
    'keydown .feedback-comment-text-input': 'keydownCommentText'
    'keydown .confirm-delete': 'keydownConfirmDelete'
    'click .feedback-comment.editable': 'editCommentText'
    'click .btn-cancel-delete-comment': 'cancelDeleteComment'
    'click .btn-delete-comment': 'deleteComment'
    'click #toggle_extra_tags_link': 'toggleExtraTags'
    'click .feedback-tag-cloud > .feedback-tag': 'clickTag'
    'click .feedback-search-example': 'clickExample'
    'click .feedback-query': 'clickQuery'
    'click .feedback-customer-identify': 'identifyCustomer'
    'click .btn-read': 'toggleRead'
    'click .feedback-conversation-copy': 'copy'
    'click .feedback-signal-strength-selector .dropdown-menu a': 'clickSignalStrength'
    'click .snippet-link': 'selectSnippet'

  initialize: (options)->
    @options = options
    @$results = @$el.find('#results')
    @renderComment = Handlebars.helpers.renderComment
    @sortedConversations = @conversations = @options.conversations
    @tags = @options.tags
    @projects = @options.projects
    @customers = @options.customers
    @canCopy = window.ClipboardEvent and ('clipboardData' in _.keys(ClipboardEvent.prototype))
    @_query = @$el.find('#q').val()
    @sortOrder = 'rank'

    Houston.shortcuts.describe "Esc", "Jump to the search box"

    Houston.shortcuts.create "mod+k mod+r", "Mark selected feedback as read", (e) =>
      e.preventDefault()
      for conversation in @selectedConversations
        @markAsRead(conversation)

    Houston.shortcuts.create "mod+k mod+shift+r", "Mark selected feedback as unread", (e) =>
      e.preventDefault()
      for conversation in @selectedConversations
        @markAsUnread(conversation)

    Houston.shortcuts.create "mod+k mod+e", "Edit the selected feedback", (e) =>
      e.preventDefault()
      @editConversationText()

    Houston.shortcuts.create "mod+k mod+a", "Archive selected feedback", (e) =>
      e.preventDefault()
      @archiveConversation()

    Houston.shortcuts.create "mod+k mod+shift+a", "Unarchive selected feedback", (e) =>
      e.preventDefault()
      @unarchiveConversation()

    _.each [1..4], (i) =>
      Houston.shortcuts.create "mod+k mod+#{i}", "Set signal strength to #{i}", (e) =>
        e.preventDefault()
        for conversation in @selectedConversations
          @setSignalStrength conversation, i

    Houston.shortcuts.create "mod+k mod+0", "Erase signal strength", (e) =>
      e.preventDefault()
      for conversation in @selectedConversations
        @setSignalStrength conversation, null

    # Used to work with selection:
    #  - to determine character ranges from selection
    #  - to create a selection from character ranges
    #  - to style selected text
    #
    # This is nontrivial work since a selection may span
    # more than one block element. Rangy can convert that
    # to an array of text ranges and wrap them in spans.
    #
    # https://github.com/timdown/rangy/wiki
    #
    rangy.init()

    # Create a snippet
    Houston.shortcuts.create "mod+k mod+s", "Create snippet from selected text", (e) =>
      e.preventDefault()
      @createSnippet()

    $('#import_csv_field').change (e)->
      $(e.target).closest('form').submit()

      # clear the field so that if we select the same
      # file again, we get another 'change' event.
      $(e.target).val('').attr('type', 'text').attr('type', 'file')

    $('#feedback_csv_upload_target').on 'upload:complete', (e, data)=>
      if data.ok
        @promptToImportCsv(data)
      else
        alertify.error """
        <b>There is a problem with the file "#{data.filename}"</b><br/>
        #{data.error}
        """

    $('#new_feedback_button').click =>
      @newFeedback()

    $('#q').autocompleteQuery(@tags)

    if @options.infiniteScroll
      new InfiniteScroll
        load: ($what)=>
          promise = new $.Deferred()
          @offset += 50
          promise.resolve @template
            conversations: (conversation.toJSON() for conversation in @sortedConversations.slice(@offset, @offset + 50))
          promise

    @editNothing()



  resultFocused: (e)->
    $('.feedback-search-result.anchor').removeClass('anchor')
    $result = $(e.target)
    $result.addClass('anchor')

    return if @resultIsBeingClicked

    @select e.target, 'new' unless $result.is('.selected')

  resultClicked: (e)->
    @resultIsBeingClicked = true
    @select e.target, @mode(e)

  resultReleased: (e)->
    @resultIsBeingClicked = false
    @focusEditor()

  mode: (e)->
    return 'toggle' if e.metaKey or e.ctrlKey
    return 'lasso' if e.shiftKey
    'new'

  select: (conversation, mode)->
    $el = @$conversation(conversation)

    $anchor = $('.feedback-search-result.anchor')
    mode = 'new' if mode is 'lasso' and $anchor.length is 0

    switch mode
      when 'toggle'
        $el.toggleClass('selected')
        $el.focus() if $el.hasClass('selected') and !$el.is(':focus')

      when 'lasso'
        $range = @$results.children().between($anchor, $el)
        $range.addClass('selected')

      else
        @$selection().removeClass('selected')
        $el.addClass('selected')
        $el.focus() unless $el.is(':focus')

    @selectedConversations = _.compact(@conversations.get(id) for id in @selectedIds())
    @$el.toggleClass 'feedback-selected', @selectedConversations.length > 0
    @editSelected()

  $selection: ->
    @$el.find('.feedback-search-result.selected')

  selectedIds: ->
    $(el).attr('data-id') for el in @$selection()

  selectedId: ->
    ids = @selectedIds()
    throw "Expected only one conversation to be selected, but there are #{ids.length}" unless ids.length is 1
    ids[0]

  selectPrev: (mode)->
    $prev = @$selection().first().prev('.feedback-search-result')
    if $prev and $prev.length > 0
      @select $prev, mode
    else if mode is 'new'
      @focusSearch()

  selectNext: (mode)->
    $next = @$selection().last().next('.feedback-search-result')
    if $next and $next.length > 0
      @select $next, mode

  selectNone: ->
    @select null, 'new'

  $conversation: (conversation)->
    return $() unless conversation
    return @$conversation conversation[0] if _.isArray(conversation)
    return @$conversation conversation.target if conversation.target
    return $("#conversation_#{conversation.id}") if conversation.constructor is Houston.Feedback.Conversation
    $(conversation).closest('.feedback-search-result')

  keydown: (e)->
    return true if $(e.target).closest('#new_feedback').length > 0
    switch e.keyCode
      when KEY.UP then @selectPrev(@mode(e))
      when KEY.DOWN then @selectNext(@mode(e))
      when KEY.ESC
        if @selectedSnippetIndex > 0
          @selectedSnippetIndex = 0
          @redrawSnippets()
        else
          @focusSearch()
      when KEY.DELETE
        return unless e.metaKey
        return unless _.all @selectedConversations, (conversation)=> conversation.get('permissions').destroy
        e.preventDefault()
        ids = (conversation.id for conversation in @selectedConversations)
        @_deleteConversations(conversation_ids: ids)

  keydownSearch: (e)->
    if e.keyCode is KEY.DOWN
      e.stopImmediatePropagation()
      @selectFirstResult()

  onFocusSearch: ->
    @selectNone()

  selectFirstResult: ->
    @select @$el.find('.feedback-search-result:first'), 'new'

  selectConversation: (id)->
    @select @$el.find("#conversation_#{id}"), 'new'

  submitSearch: (e)->
    @search(e)

  resetSearch: (e)->
    $('#q').val ""
    @search(e)
    $('#search_feedback').addClass('unperformed')

  search: (e = {})->
    return unless history.pushState

    $('#search_feedback').removeClass('unperformed')

    e.preventDefault() if e?.preventDefault
    @_query = $('#q').val()
    xlsxHref = window.location.pathname + '.xlsx?' + $.param(q: @_query)
    url = @pushState {}
    $('#excel_export_button').attr('href', xlsxHref)
    start = new Date()
    $.getJSON url, (conversations)=>
      @selectNone() if e.selectNone ? true
      @conversations = new Houston.Feedback.Conversations(conversations, parse: true)
      @sortedConversations = @applySort(@conversations)
      @searchTime = (new Date() - start)
      @render()
      @focusSearch() if e.selectNone ? true

  sort: ->
    @sortOrder = $('#sort_feedback').val()
    @pushState()
    @sortedConversations = @applySort(@conversations)
    @render()
    @focusSearch()

  applySort: (conversations) ->
    console.log("sorting #{conversations.length} conversations by #{@sortOrder}")
    switch @sortOrder
      when "rank" then conversations
      when "added" then conversations.sortBy("createdAt").reverse()
      when "signal_strength" then conversations.sortBy("averageSignalStrength").reverse()
      when "customer" then conversations.sortBy (conversation) -> conversation.attribution().toLowerCase()
      when "length" then conversations.sortBy((conversation) -> Handlebars.helpers.wordCount(conversation.get('text'))).reverse()
      when "brevity" then conversations.sortBy((conversation) -> Handlebars.helpers.wordCount(conversation.get('text')))
      else
        console.log("Unknown sort order: #{@sortOrder}")
        conversations



  render: ->
    @offset = 0
    html = @template(conversations: (conversation.toJSON() for conversation in @sortedConversations.slice(0, 50)))
    @$results.html(html).removeClass("done")

    @$el.find('#search_report').html @renderSearchReport
      results: @conversations.length
      searchTime: @searchTime

    tags = @conversations.countTags()
    $('#tags_report').html @renderTagCloud
      topTags: tags.slice(0, MAX_TAGS)
      extraTags: tags.slice(MAX_TAGS)

  focusSearch: ->
    @selectNone()
    window.scrollTo(0, 0)
    $('#search_feedback input').focus().select()

  pushState: (params={}) ->
    return unless history.pushState
    params.q = @_query
    params.sort = @sortOrder
    url = "#{window.location.pathname}?#{$.param(params)}"
    history.pushState({}, '', url)
    url

  editSelected: ->
    if @toolbar
      @toolbar.destroy()
      @toolbar = null

    count = if @selectedConversations then @selectedConversations.length else 0

    if count is 1
      @pushState focus: @selectedConversations[0].id
      @editConversation @selectedConversations[0]
    else if count > 1
      @pushState {}
      @editMultiple @selectedConversations
    else
      @pushState {}
      @editNothing()

  editConversation: (conversation)->
    if @timeoutId
      window.clearTimeout(@timeoutId)
      @timeoutId = null

    if conversation.isUnread()
      @timeoutId = window.setTimeout =>
        @markAsRead conversation, ->
          $('.feedback-conversation.feedback-edit-conversation .btn-read').addClass('active')
      , 1500

    @selectedSnippetIndex = 0
    context = conversation.toJSON()
    context.index = $('.feedback-conversation.selected').index() + 1
    context.total = @conversations.length
    context.canCopy = @canCopy
    $('#feedback_edit').html @renderEditConversation(context)
    $('#feedback_edit .uploader').supportImages()
    $('#feedback_edit .feedback-comment-text-input').autosize()

    el = $('#feedback_edit .feedback-text.markdown')[0]
    @toolbar = new SelectionToolbar(el)
    @toolbar.use [ {
      name: "Make Snippet"
      action: => @createSnippet()
    } ]

    @redrawSnippets()

  redrawSnippets: ->
    conversation = @selectedConversations[0]
    snippets = conversation.snippets()
    hasSnippets = snippets.length > 1
    selectedSnippetIndex = @selectedSnippetIndex
    isSnippet = @selectedSnippetIndex > 0

    context = conversation.toJSON()
    context.isSnippet = isSnippet

    $('#feedback_commands').html @renderFeedbackCommands(context)

    $el = $('#feedback_edit .feedback-text.markdown')
    el = $el[0]

    allText = rangy.createRange()
    allText.selectNode(el)
    rangy.createClassApplier("snippet").undoToRange(allText)
    rangy.createClassApplier("snippet-link").undoToRange(allText)

    selection = rangy.getSelection()
    if isSnippet
      $el.addClass("feedback-text-snippet")
      snippet = snippets[@selectedSnippetIndex]
      selection.selectCharacters(el, snippet.highlight.start, snippet.highlight.end)

      range = selection.getRangeAt(0).nativeRange.getBoundingClientRect()
      range = selection.nativeSelection.getRangeAt(0).getBoundingClientRect()
      offset = $el.offset()
      $el.find(".feedback-text-snippet-marker").css
        top: range.top - offset.top
        height: range.height

      snippetClassApplier = rangy.createClassApplier("snippet")
      snippetClassApplier.applyToRanges selection.getAllRanges()

      $('#feedback_tags').html(
        Handlebars.helpers.renderFeedbackTagsReadonly(context.tags) +
        Handlebars.helpers.renderFeedbackTags(snippet.tags))

    else
      $el.removeClass("feedback-text-snippet")
      for snippet, i in snippets when snippet.highlight
        selection.selectCharacters(el, snippet.highlight.start, snippet.highlight.end)
        snippetClassApplier = rangy.createClassApplier "snippet-link",
          elementTagName: "span"
          elementAttributes: {"data-snippet-index": i}
        snippetClassApplier.applyToRanges selection.getAllRanges()

      $('#feedback_tags').html Handlebars.helpers.renderFeedbackTags(context.tags)

    window.getSelection().removeAllRanges()
    @focusEditor()

  selectSnippet: (e)->
    @selectedSnippetIndex = +$(e.target).closest(".snippet-link").attr("data-snippet-index")
    @redrawSnippets()

  editMultiple: (conversations)->
    context =
      count: conversations.length
      permissions:
        destroy: _.all conversations, (conversation)-> conversation.get('permissions').destroy
        update: _.all conversations, (conversation)-> conversation.get('permissions').update
        addComment: _.all conversations, (conversation)-> conversation.get('permissions').addComment
      tags: []
      archived: _.all conversations, (conversation)-> conversation.get('archived')
      read: _.all conversations, (conversation)-> conversation.get('read')

    tags = _.flatten(conversation.get('tags') for conversation in conversations)
    for tag, array of _.groupBy(tags)
      tag.count = array.length
      percent = array.length / context.count
      percent = 0.2 if percent < 0.2
      context.tags.push
        name: tag
        percent: percent

    $('#feedback_edit').html @renderEditMultiple(context)
    @focusEditor()

  editNothing: ->
    $('#feedback_edit').html @renderSearchInstructions
      exampleOfThreeWeeksAgo: "by:me added:#{d3.time.format('%Y%m%d')(3.weeks().before(new Date()))}.."

  focusEditor: ->
    $('#feedback_edit').find('input').autocompleteTags(@tags).focus()

  removeTag: (e)->
    e.preventDefault()
    e.stopImmediatePropagation()
    $tag = $(e.target).closest('.feedback-tag')
    tag = $tag.text().replace(/\s/g, '')
    ids = @selectedIds()
    tags = [tag]

    if @selectedSnippetIndex > 0
      conversation = @selectedConversations[0]
      conversation.removeTagsFromSnippet(tags, @selectedSnippetIndex)
        .done (snippet) =>
          $('#feedback_tags').html(
            Handlebars.helpers.renderFeedbackTagsReadonly(conversation.get('tags')) +
            Handlebars.helpers.renderFeedbackTags(snippet.tags))
    else
      $.destroy '/feedback/conversations/tags', conversation_ids: ids, tags: tags
        .success =>
          @conversations.get(id).removeTags(tags) for id in ids
          @editSelected()
        .error ->
          console.log 'error', arguments

  keydownNewTag: (e)->
    if e.keyCode is KEY.RETURN
      e.preventDefault()
      e.stopImmediatePropagation()
      @addTag()
    if e.keyCode in [KEY.DOWN, KEY.UP]
      @addTag()

  addTag: ->
    $input = $('.feedback-new-tag')
    tags = $input.selectedTags()
    return if tags.length is 0

    if @selectedSnippetIndex > 0
      conversation = @selectedConversations[0]
      conversation.addTagsToSnippet(tags, @selectedSnippetIndex)
        .done (snippet) =>
          $('#feedback_tags').html(
            Handlebars.helpers.renderFeedbackTagsReadonly(conversation.get('tags')) +
            Handlebars.helpers.renderFeedbackTags(snippet.tags))
          $input.val ''

    else
      ids = @selectedIds()
      $.post '/feedback/conversations/tags', conversation_ids: ids, tags: tags
        .success =>
          @tags = _.uniq @tags.concat(tags)
          for id in ids
            conversation = @conversations.get(id)
            conversation.addTags(tags)
            $('#feedback_tags').html Handlebars.helpers.renderFeedbackTags(conversation.get('tags'))
          @editSelected()
        .error ->
          console.log 'error', arguments

  promptToImportCsv: (data)->
    $modal = $(@renderImportModal(data)).modal()
    $modal.on 'hidden', -> $(@).remove()

    for heading in data.headings
      if heading.text in data.customerFields
        $("#customer_field_#{heading.index}").prop "checked", true

    addTags = @activateTagControls($modal)

    $modal.find('#import_button').click =>
      addTags()

      $modal.find('button').prop('disabled', true)
      params = $modal.find('form').serializeObject()
      $.post "#{window.location.pathname}/import", params
        .success (response)=>
          $modal.modal('hide')
          alertify.success "#{response.count} conversations imported"
          tags = params["tags[]"]
          if tags
            tags = [tags] unless _.isArray(tags)
            tags = _.uniq(tags)
            $("#q").val _.map(tags, (tag)-> "##{tag}").join(" ")
          @search()
        .error ->
          console.log 'error', arguments
          $modal.find('button').prop('disabled', false)



  deleteConversations: (e)->
    e.preventDefault()
    ids = @selectedIds()
    imports = _.uniq(@conversations.get(id).get('import') for id in ids)
    if imports.length is 1 and imports[0]
      $modal = $(@renderDeleteImportedModal()).modal()
      $modal.on 'hidden', -> $(@).remove()
      $modal.find('#delete_selected').click =>
        $modal.modal('hide')
        @_deleteConversations(conversation_ids: ids)
      $modal.find('#delete_imported').click =>
        $modal.modal('hide')
        @_deleteConversations(import: imports[0])
    else
      $modal = $(@renderConfirmDeleteModal()).modal()
      $modal.on 'hidden', -> $(@).remove()
      $modal.find('#delete_conversation_button').click =>
        $modal.modal('hide')
        @_deleteConversations(conversation_ids: ids)

  _deleteConversations: (params)->
    $.destroy '/feedback/conversations', params
      .success (response)=>
        @selectNext() or @selectPrev() or @selectNone()

        ids = response.ids
        alertify.success "#{ids.length} conversations deleted"

        selectors = []
        for id in ids
          @conversations.remove(id)
          selectors.push "#conversation_#{id}"

        $(selectors.join(",")).remove()
      .error ->
        console.log 'error', arguments



  moveConversations: (e)->
    e.preventDefault()
    ids = @selectedIds()
    html = @renderChangeProjectModal(projects: @projects)
    $modal = $(html).modal()

    $select = $modal.find('#conversations_new_project')
    $select.change ->
      $modal.find('#move_conversations_button').prop('disabled', !$select.val())

    $modal.on 'hidden', -> $(@).remove()
    $modal.find('#move_conversations_button').click =>
      newProjectId = $modal.find('#conversations_new_project').val()
      $modal.modal('hide')
      @_moveConversations(conversation_ids: ids, project_id: newProjectId)

  _moveConversations: (params)->
    $.post '/feedback/conversations/move', params
      .success (response)=>
        @selectNext() or @selectPrev() or @selectNone()

        ids = response.ids
        alertify.success "#{ids.length} conversations moved"

        selectors = []
        for id in ids
          @conversations.remove(id)
          selectors.push "#conversation_#{id}"

        $(selectors.join(",")).remove()
      .error ->
        console.log 'error', arguments



  editConversationText: (e)->
    e.preventDefault() if e
    if @isEditingConversationText()
      @endEditConversationText()
    else
      @beginEditConversationText()

  isEditingConversationText: ->
    $('.feedback-edit-conversation').hasClass('edit-text')

  beginEditConversationText: ->
    $('.feedback-edit-conversation').addClass('edit-text')
    $('.btn-edit').text('Cancel')
    $('.feedback-edit-conversation textarea').focus()

  endEditConversationText: ->
    $('.feedback-edit-conversation').removeClass('edit-text')
    $('.btn-edit').text('Edit')
    $('.feedback-edit-conversation .feedback-new-tag').focus()

  saveConversationText: (e)->
    e.preventDefault() if e

    text = $('.feedback-text.edit textarea').val()
    attributedTo = $('.feedback-customer-edit > input').val()
    conversation = @conversations.get @selectedId()

    if conversation.get('text') is text or conversation.snippets().length <= 1
      @updateConversation(conversation, text: text, attributedTo: attributedTo)
    else
      $modal = $(@renderConfirmResetSnippetsModal()).modal()
      $modal.on 'hidden', -> $(@).remove()
      $modal.find('#reset_snippets_button').click =>
        $modal.modal('hide')
        @updateConversation(conversation, text: text, attributedTo: attributedTo)

  updateConversation: (conversation, params)->
    conversation.save(params)
      .success =>
        @redrawConversation conversation
        @editSelected()
        alertify.success "Conversation updated"
        $('.feedback-edit-conversation').removeClass('edit-text')
        $('.btn-edit').text('Edit')
      .error ->
        console.log 'error', arguments

  redrawConversation: (conversation)->
    $("#conversation_#{conversation.id}").html @renderFeedback(conversation.toJSON())

  keydownConversationText: (e)->
    # Don't select another conversation or jump to the search bar
    e.stopImmediatePropagation()
    switch e.keyCode
      when KEY.ESC then @endEditConversationText()
      when KEY.RETURN
        if e.metaKey or e.ctrlKey
          e.preventDefault()
          @saveConversationText()



  keydownCommentText: (e)->
    if e.keyCode is KEY.ESC
      # Don't jump focus back to the Search bar
      e.stopImmediatePropagation()
      e.preventDefault()

      # Maybe stop editing this comment
      $comment = $(e.target).closest(".feedback-comment")
      if $comment.hasClass("feedback-edit-comment")
        @stopEditingComment($comment)

    if e.keyCode is KEY.RETURN and !e.shiftKey
      e.stopImmediatePropagation()
      e.preventDefault()

      $comment = $(e.target).closest(".feedback-comment")
      $text = $comment.find(".feedback-comment-text-input")

      if $comment.hasClass("feedback-edit-comment")
        if $text.val() is ""
          @confirmDeleteComment $comment
        else
          @updateComment($comment)
      else
        unless $text.val() is ""
          @createComment($comment)

    if e.keyCode is KEY.DELETE
      $comment = $(e.target).closest(".feedback-comment")
      return unless $comment.hasClass("feedback-edit-comment")

      $text = $comment.find(".feedback-comment-text-input")
      return unless $text.val() is ""

      @confirmDeleteComment $comment

  confirmDeleteComment: ($comment)->
    $comment.addClass("confirming")
      .find(".confirm-delete .btn.btn-default").focus()

  keydownConfirmDelete: (e)->
    if e.keyCode is KEY.ESC
      @cancelDeleteComment(e)

  cancelDeleteComment: (e)->
    e.stopImmediatePropagation()
    e.preventDefault()

    $comment = $(e.target).closest(".feedback-comment")
    $comment.removeClass("confirming")
      .find(".feedback-comment-text-input")
      .focus()

  deleteComment: (e)->
    e.stopImmediatePropagation()
    e.preventDefault()

    $comment = $(e.target).closest(".feedback-comment")
    id = $comment.attr("data-id")
    @selectedConversations[0].deleteComment(id)
      .then (comment)=>
        $comment.remove()
      .fail (errors)->
        errors.renderToAlert()


  createComment: ($comment)->
    $text = $comment.find(".feedback-comment-text-input")
    $text.prop "disabled", true
    @selectedConversations[0].createComment($text.val())
      .then (comment)=>
        $('#comments').prepend @renderComment(comment)
        $text.prop("disabled", false).val("").focus()
      .fail (errors)->
        errors.renderToAlert()
        $text.prop "disabled", false

  updateComment: ($comment)->
    $text = $comment.find(".feedback-comment-text-input")
    $text.prop "disabled", true
    id = $comment.attr("data-id")
    @selectedConversations[0].updateComment(id, $text.val())
      .then (comment)=>
        @stopEditingComment $comment
      .fail (errors)->
        errors.renderToAlert()
        $text.prop "disabled", false

  editCommentText: (e)->
    @$el.find(".feedback-edit-comment").each (i, el)=>
      @stopEditingComment $(el)

    $comment = $(e.target).closest('.feedback-comment.editable')
    id = $comment.attr("data-id")
    comment = @selectedConversations[0].findComment(id)
    $(@renderEditComment(comment))
      .replaceAll($comment)
      .find("textarea")
      .autosize()
      .select()
      .focus()

  stopEditingComment: ($comment)->
    id = $comment.attr("data-id")
    comment = @selectedConversations[0].findComment(id)
    $(@renderComment(comment)).replaceAll($comment)



  archiveConversation: (e)->
    for conversation in @selectedConversations
      conversation.archive()
        .success =>
          @redrawConversation conversation
          $('.btn-archive').removeClass('btn-archive').addClass('btn-unarchive').html('Unarchive')

  unarchiveConversation: (e)->
    for conversation in @selectedConversations
      conversation.unarchive()
        .success =>
          @redrawConversation conversation
          $('.btn-unarchive').removeClass('btn-unarchive').addClass('btn-archive').html('Archive')



  newFeedback: (e)->
    e.preventDefault() if e

    $('#q').val "by:me added:today"
    @search(selectNone: false)

    $('#feedback_edit').html @renderNewConversation()
    $('#new_feedback_customer').focus()
    $('#new_feedback_form .uploader').supportImages()
    @activateTagControls $('#new_feedback_form')
    $('#new_feedback_text, #new_feedback_tags').keydown (e) =>
      if e.keyCode is 13 and (e.metaKey or e.ctrlKey)
        @createFeedback()
    $('#create_feedback').click => @createFeedback()

  createFeedback: ->
    params = $('#new_feedback_form').serializeObject()
    params.tags = $('#new_feedback_tags').selectedTags()
    $.post window.location.pathname, params
      .success =>
        @search(selectNone: false)
        alertify.success "Comment created"
        $('#new_feedback_tags').val('')
        $('#new_feedback_text').val('').focus()
      .error ->
        console.log 'error', arguments

  activateTagControls: ($el)->
    $el.find('#new_feedback_tags').autocompleteTags(@tags)
    $newTag = $el.find('.feedback-new-tag')

    addTags = =>
      tags = $newTag.selectedTags()
      $tags = $el.find('.feedback-tag-list')
      for tag in tags
        $tags.append """
          <span class="feedback-tag feedback-tag-new">
            #{tag}
            <input type="hidden" name="tags[]" value="#{tag}" />
            <a class="feedback-remove-tag"><i class="fa fa-close"></i></a>
          </span>
        """
      $newTag.val('')

    $newTag.keydown (e)->
      if e.keyCode is KEY.RETURN
        unless e.metaKey or e.ctrlKey
          e.preventDefault()
          addTags()

    $el.on 'click', '.feedback-remove-tag', (e)->
      $(e.target).closest('.feedback-tag-new').remove()
      $el.find('.feedback-new-tag').focus()

    addTags


  markAsRead: (conversation, callback)->
    conversation.markAsRead ->
      $(".feedback-search-result.feedback-conversation[data-id=\"#{conversation.get('id')}\"]")
        .removeClass('feedback-conversation-unread')
        .addClass('feedback-conversation-read')
      callback() if callback

  markAsUnread: (conversation, callback)->
    conversation.markAsUnread ->
      $(".feedback-search-result.feedback-conversation[data-id=\"#{conversation.get('id')}\"]")
        .addClass('feedback-conversation-unread')
        .removeClass('feedback-conversation-read')
      callback() if callback

  clickSignalStrength: (e) ->
    value = $(e.target).closest("a").data("value")
    for conversation in @selectedConversations
      @setSignalStrength(conversation, value)

  setSignalStrength: (conversation, i, callback) ->
    conversation.setSignalStrength i, ->
      $("#conversation_#{conversation.get('id')}.feedback-search-result .feedback-conversation-signal-strength")
        .html(Handlebars.helpers.signalStrengthImage(conversation.get('averageSignalStrength'), {hash: {size: 16}}))
      $("#feedback_edit .feedback-conversation-signal-strength")
        .html(Handlebars.helpers.signalStrengthImage(i, {hash: {size: 20}}))
      callback() if callback



  toggleExtraTags: (e)->
    e.preventDefault() if e
    $a = $(e.target)
    $a.toggleClass('show-all-tags')
    $('#extra_tags').toggleClass 'collapsed', !$a.hasClass('show-all-tags')

  clickTag: (e)->
    e.preventDefault() if e
    $a = $(e.target).closest('a')
    tag = @getQuery $a.attr('href')
    q = $('#q').val()
    q = if q.length then "#{q} #{tag}" else tag
    $('#q').val q
    @search()

  clickExample: (e)->
    e.preventDefault() if e
    q = @getQuery $(e.target).attr('href')
    $('#q').val q
    @search()

  clickQuery: (e)->
    e.preventDefault() if e
    q = @getQuery $(e.target).attr('href')
    $('#q').val q
    @search()

  getQuery: (params)->
    @getParameterByName(params, 'q')

  # http://james.padolsey.com/javascript/bujs-1-getparameterbyname/
  getParameterByName: (params, name)->
    match = RegExp("[?&]#{name}=([^&]*)").exec(params)
    decodeURIComponent(match[1].replace(/\+/g, ' ')) if match



  toggleRead: (e)->
    if !$(e.target).hasClass('active')
      for conversation in @selectedConversations
        @markAsRead(conversation)
    else
      for conversation in @selectedConversations
        @markAsUnread(conversation)



  copy: (e)->
    e.preventDefault()

    # I only show the *Copy* button when there's one
    # selected conversation right now, so make that assumption.
    conversation = @selectedConversations[0]

    $(document).one "copy", (e)=>
      e = e.originalEvent || e
      e.clipboardData.setData "text/plain", conversation.text()
      e.clipboardData.setData "text/html", conversation.html()
      e.preventDefault()

    document.execCommand "copy"
    alertify.success("Feedback copied!")

  copyUrl: (e)->
    e.preventDefault()

    # I only show the *Copy* button when there's one
    # selected conversation right now, so make that assumption.
    conversation = @selectedConversations[0]
    url = App.meta("relative_url_root") + "feedback/#{conversation.id}"

    $(document).one "copy", (e)=>
      e = e.originalEvent || e
      e.clipboardData.setData "text/plain", url
      e.preventDefault()

    document.execCommand "copy"
    alertify.success("Short URL copied!")



  identifyCustomer: (e)->
    e.preventDefault()

    conversation = @selectedConversations[0]
    attribution = conversation.get('attributedTo')

    html = @renderIdentifyCustomerModal
      customers: @customers
    $modal = $(html).modal()
    $modal.on 'hidden', -> $(@).remove()
    $modal.find('#customer_name').focus()

    $modal.find('#customer_id').change ->
      $modal.find('#identify_customer_mode_existing').prop('checked', true)

    $modal.find('#customer_name').focus ->
      $modal.find('#identify_customer_mode_new').prop('checked', true)

    $modal.find('#identify_customer_button').click =>
      if $modal.find('#identify_customer_mode_existing').prop('checked')
        id = $modal.find('#customer_id').val()
        return unless id

        promise = $.post "/feedback/customers/#{id}/attribution",
          attribution: attribution
      else
        name = $modal.find('#customer_name').val()
        promise = $.post "/feedback/customers",
          attribution: attribution
          name: name

      promise.success =>
        window.location.reload()
      promise.error ->
        console.log 'error', arguments
      $modal.modal('hide')



  createSnippet: ->
    @toolbar.hideToolbar()

    selection = rangy.getSelection()
    $context = $(selection.anchorNode).closest('.feedback-edit-conversation .feedback-text.markdown')
    return unless $context.length > 0

    conversation = @selectedConversations[0]
    range = selection.saveCharacterRanges($context[0])[0]
    snippet =
      range: [range.characterRange.start, range.characterRange.end]
      text: selection.toString()
    conversation.addSnippet(snippet)
      .done (index) =>
        @selectedSnippetIndex = index
        @redrawSnippets()

  deleteSnippet: (e) ->
    e.preventDefault()
    conversation = @selectedConversations[0]
    conversation.deleteSnippet @selectedSnippetIndex
      .done =>
        @selectedSnippetIndex = 0
        @redrawSnippets()
