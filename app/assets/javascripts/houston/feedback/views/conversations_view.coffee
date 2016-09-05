KEY =
  DELETE: 8
  TAB: 9
  RETURN: 13
  ESC: 27
  UP: 38
  DOWN: 40

class Houston.Feedback.ConversationsView extends Backbone.View
  template: HandlebarsTemplates['houston/feedback/conversations/index']
  renderFeedback: HandlebarsTemplates['houston/feedback/conversations/show']
  renderEditConversation: HandlebarsTemplates['houston/feedback/conversations/edit']
  renderEditMultiple: HandlebarsTemplates['houston/feedback/conversations/edit_multiple']
  renderSearchReport: HandlebarsTemplates['houston/feedback/conversations/report']
  renderImportModal: HandlebarsTemplates['houston/feedback/conversations/import']
  renderConfirmDeleteModal: HandlebarsTemplates['houston/feedback/conversations/confirm_delete']
  renderDeleteImportedModal: HandlebarsTemplates['houston/feedback/conversations/delete_imported']
  renderChangeProjectModal: HandlebarsTemplates['houston/feedback/conversations/change_project']
  renderIdentifyCustomerModal: HandlebarsTemplates['houston/feedback/conversations/identify_customer']
  renderNewConversationModal: HandlebarsTemplates['houston/feedback/conversations/new']
  renderTagCloud: HandlebarsTemplates['houston/feedback/conversations/tags']
  renderSearchInstructions: HandlebarsTemplates['houston/feedback/search_instructions']

  events:
    'submit #search_feedback': 'submitSearch'
    'change #sort_feedback': 'sort'
    'click #feedback_search_reset': 'resetSearch'
    'focus .feedback-search-result': 'resultFocused'
    'mousedown .feedback-search-result': 'resultClicked'
    'mouseup .feedback-search-result': 'resultReleased'
    'keydown': 'keydown'
    'keydown #q': 'keydownSearch'
    'click .feedback-conversation-close': 'selectNone'
    'click .feedback-conversation-copy-url': 'copyUrl'
    'click .feedback-remove-tag': 'removeTag'
    'keydown .feedback-new-tag': 'keydownNewTag'
    'click .btn-delete': 'deleteConversations'
    'click .btn-move': 'moveConversations'
    'click .btn-edit': 'editConversationText'
    'click .btn-save': 'saveConversationText'
    'click .btn-archive': 'archiveConversation'
    'click .btn-unarchive': 'unarchiveConversation'
    'keydown .feedback-text textarea': 'keydownConversationText'
    'click #toggle_extra_tags_link': 'toggleExtraTags'
    'click .feedback-tag-cloud > .feedback-tag': 'clickTag'
    'click .feedback-search-example': 'clickExample'
    'click .feedback-query': 'clickQuery'
    'click .feedback-customer-identify': 'identifyCustomer'
    'click .btn-read': 'toggleRead'
    'click .feedback-conversation-copy': 'copy'
    'click .feedback-signal-strength-selector .dropdown-menu a': 'clickSignalStrength'

  initialize: ->
    @$results = @$el.find('#results')
    @sortedConversations = @conversations = @options.conversations
    @tags = @options.tags
    @projects = @options.projects
    @customers = @options.customers
    @canCopy = window.ClipboardEvent and ('clipboardData' in _.keys(ClipboardEvent.prototype))
    @sortOrder = 'rank'

    Mousetrap.bind "command+k command+r", (e) =>
      e.preventDefault()
      for conversation in @selectedConversations
        @markAsRead(conversation)

    Mousetrap.bind "command+k command+u", (e) =>
      e.preventDefault()
      for conversation in @selectedConversations
        @markAsUnread(conversation)

    Mousetrap.bind "command+k command+e", (e) =>
      e.preventDefault()
      @editConversationText()

    Mousetrap.bind "command+k command+a", (e) =>
      e.preventDefault()
      @archiveConversation()

    Mousetrap.bind "command+k command+shift+a", (e) =>
      e.preventDefault()
      @unarchiveConversation()

    _.each [1..4], (i) =>
      Mousetrap.bind "command+k command+#{i}", (e) =>
        e.preventDefault()
        for conversation in @selectedConversations
          @setSignalStrength conversation, i

    Mousetrap.bind "command+k command+0", (e) =>
      e.preventDefault()
      for conversation in @selectedConversations
        @setSignalStrength conversation, null

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

    if @options.infiniteScroll
      new InfiniteScroll
        load: ($what)=>
          promise = new $.Deferred()
          @offset += 50
          promise.resolve @template
            conversations: (conversation.toJSON() for conversation in @sortedConversations.slice(@offset, @offset + 50))
          promise



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
    switch e.keyCode
      when KEY.UP then @selectPrev(@mode(e))
      when KEY.DOWN then @selectNext(@mode(e))
      when KEY.ESC then @focusSearch()
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

  selectFirstResult: ->
    @select @$el.find('.feedback-search-result:first'), 'new'

  submitSearch: (e)->
    @search(e)

  resetSearch: (e)->
    $('#q').val ""
    @search(e)
    $('#search_feedback').addClass('unperformed')

  search: (e)->
    return unless history.pushState

    $('#search_feedback').removeClass('unperformed')

    e.preventDefault() if e
    search = $('#search_feedback').serialize()
    url = window.location.pathname
    url = url + '?' + search
    xlsxHref = window.location.pathname + '.xlsx?' + search
    history.pushState({}, '', url)
    $('#excel_export_button').attr('href', xlsxHref)
    start = new Date()
    $.getJSON url, (conversations)=>
      @selectNone()
      @conversations = new Houston.Feedback.Conversations(conversations, parse: true)
      @sortedConversations = @applySort(@conversations)
      @searchTime = (new Date() - start)
      @render()

  sort: ->
    @sortOrder = $('#sort_feedback').val()
    @sortedConversations = @applySort(@conversations)
    @render()

  applySort: (conversations) ->
    console.log("sorting #{conversations.length} conversations by #{@sortOrder}")
    switch @sortOrder
      when "rank" then conversations
      when "added" then conversations.sortBy("createdAt").reverse()
      when "signal_strength" then conversations.sortBy("averageSignalStrength").reverse()
      when "customer" then conversations.sortBy (conversation) -> conversation.attribution().toLowerCase()
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
      topTags: tags.slice(0, 5)
      extraTags: tags.slice(5)

    @focusSearch()

  focusSearch: ->
    @selectNone()
    window.scrollTo(0, 0)
    $('#search_feedback input').focus().select()

  editSelected: ->
    if @selectedConversations.length is 1
      @editConversation @selectedConversations[0]
    else if @selectedConversations.length > 1
      @editMultiple @selectedConversations
    else
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

    context = conversation.toJSON()
    context.index = $('.feedback-conversation.selected').index() + 1
    context.total = @conversations.length
    context.canCopy = @canCopy
    $('#feedback_edit').html @renderEditConversation(context)
    $('#feedback_edit .uploader').supportImages()
    @focusEditor()

  editMultiple: (conversations)->
    context =
      count: conversations.length
      permissions:
        destroy: _.all conversations, (conversation)-> conversation.get('permissions').destroy
        update: _.all conversations, (conversation)-> conversation.get('permissions').update
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
    ids = @selectedIds()
    $.post '/feedback/conversations/tags', conversation_ids: ids, tags: tags
      .success =>
        @tags = _.uniq @tags.concat(tags)
        for id in ids
          conversation = @conversations.get(id)
          conversation.addTags(tags)
          @redrawConversation conversation
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
    $('.feedback-edit-conversation textarea').autosize().focus()

  endEditConversationText: ->
    $('.feedback-edit-conversation').removeClass('edit-text')
    $('.btn-edit').text('Edit')
    $('.feedback-edit-conversation .feedback-new-tag').focus()

  saveConversationText: (e)->
    e.preventDefault() if e

    text = $('.feedback-text.edit textarea').val()
    attributedTo = $('.feedback-customer-edit > input').val()
    conversation = @conversations.get @selectedId()
    conversation.save(text: text, attributedTo: attributedTo)
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
    $modal = $(@renderNewConversationModal()).modal()
    $modal.on 'hidden', -> $(@).remove()

    $modal.find('#new_feedback_customer').focus()
    $modal.find('.uploader').supportImages()

    addTags = @activateTagControls($modal)

    submit = =>
      addTags()
      params = $modal.find('form').serialize()
      $.post window.location.pathname, params
        .success =>
          $modal.modal('hide')
          alertify.success "Conversation created"
          @search()
        .error ->
          console.log 'error', arguments

    $modal.find('.feedback-new-tag').keydown (e)->
      if e.keyCode is KEY.RETURN
        if e.metaKey or e.ctrlKey
          submit()

    $modal.find('#create_button').click => submit()

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
      $("#conversation_#{conversation.get('id')}.feedback-edit-conversation .feedback-conversation-signal-strength")
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
