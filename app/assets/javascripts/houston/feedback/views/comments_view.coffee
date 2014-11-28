KEY =
  TAB: 9
  RETURN: 13
  ESC: 27
  UP: 38
  DOWN: 40

class Houston.Feedback.CommentsView extends Backbone.View
  template: HandlebarsTemplates['houston/feedback/comments/index']
  renderEditComment: HandlebarsTemplates['houston/feedback/comments/edit']
  renderEditMultiple: HandlebarsTemplates['houston/feedback/comments/edit_multiple']
  renderSearchReport: HandlebarsTemplates['houston/feedback/comments/report']
 
  events:
    'submit #search_feedback': 'search'
    'focus .feedback-search-result': 'resultFocused'
    'mousedown .feedback-search-result': 'resultClicked'
    'mouseup .feedback-search-result': 'resultReleased'
    'keydown': 'keydown'
    'click .feedback-comment-close': 'selectNone'
    'click .feedback-remove-tag': 'removeTag'
    'keydown .feedback-new-tag': 'keydownNewTag'
  
  initialize: ->
    @$results = @$el.find('#results')
    @comments = @options.comments
    
    if @options.infiniteScroll
      new InfiniteScroll
        load: ($what)=>
          promise = new $.Deferred()
          @offset += 50
          promise.resolve @template
            comments: (comment.toJSON() for comment in @comments.slice(@offset, @offset + 50))
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
  
  select: (comment, mode)->
    $el = @$comment(comment)
    
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
    
    @selectedComments = (@comments.get(id) for id in @selectedIds())
    @$el.toggleClass 'feedback-selected', @selectedComments.length > 0
    @editSelected()

  $selection: ->
    @$el.find('.feedback-search-result.selected')

  selectedIds: ->
    $(el).attr('data-id') for el in @$selection()

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

  $comment: (comment)->
    return $() unless comment
    return @$comment comment[0] if _.isArray(comment)
    return @$comment comment.target if comment.target
    return $("#comment_#{comment.id}") if comment.constructor is Houston.Feedback.Comment
    $(comment).closest('.feedback-search-result')

  keydown: (e)->
    switch e.keyCode
      when KEY.UP then @selectPrev(@mode(e))
      when KEY.DOWN then @selectNext(@mode(e))
      when KEY.ESC then @focusSearch()

  search: (e)->
    return unless history.pushState

    e.preventDefault()
    search = $('#search_feedback').serialize()
    url = window.location.pathname + '?' + search
    history.pushState({}, '', url)
    start = new Date()
    $.getJSON url, (comments)=>
      @selectNone()
      @comments = new Houston.Feedback.Comments(comments, parse: true)
      @searchTime = (new Date() - start)
      @render()

  render: ->
    @offset = 0
    html = @template(comments: (comment.toJSON() for comment in @comments.slice(0, 50)))
    @$results.html(html)

    @$el.find('#search_report').html @renderSearchReport
      results: @comments.length
      searchTime: @searchTime

    @focusSearch()

  focusSearch: ->
    window.scrollTo(0, 0)
    $('#search_feedback input').focus().select()

  editSelected: ->
    if @selectedComments.length is 1
      @editComment @selectedComments[0]
    else if @selectedComments.length > 1
      @editMultiple @selectedComments
    else
      @editNothing()

  editComment: (comment)->
    $('#feedback_edit').html @renderEditComment(comment.toJSON())
    @focusEditor()

  editMultiple: (comments)->
    context = 
      count: comments.length
      tags: []
    
    tags = (comment.get('tags') for comment in comments).flatten()
    for tag, array of tags.groupBy()
      tag.count = array.length
      percent = array.length / context.count
      percent = 0.2 if percent < 0.2
      context.tags.push
        name: tag
        percent: percent
    
    $('#feedback_edit').html @renderEditMultiple(context)
    @focusEditor()

  editNothing: ->
    $('#feedback_edit').html('')

  focusEditor: ->
    $('#feedback_edit').find('input').focus()

  removeTag: (e)->
    e.preventDefault()
    e.stopImmediatePropagation()
    $tag = $(e.target).closest('.feedback-tag')
    tag = $tag.text().replace(/\s/g, '')
    ids = @selectedIds()
    tags = [tag]
    $.destroy '/feedback/comments/tags', comment_ids: ids, tags: tags
      .success =>
        @comments.get(id).removeTags(tags) for id in ids
        @editSelected()
      .error ->
        console.log 'error', arguments

  keydownNewTag: (e)->
    if e.keyCode is KEY.RETURN
      e.preventDefault()
      e.stopImmediatePropagation()
      @addTag()

  addTag: ->
    $input = $('.feedback-new-tag')
    tags = $input.val().split(/[,;]/).map (tag)->
      tag.compact().toLowerCase().replace(/\s+/, '-')
    ids = @selectedIds()
    $.post '/feedback/comments/tags', comment_ids: ids, tags: tags
      .success =>
        @comments.get(id).addTags(tags) for id in ids
        @editSelected()
      .error ->
        console.log 'error', arguments
