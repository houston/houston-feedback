class Houston.Feedback.Comment extends Backbone.Model
  urlRoot: '/feedback/comments'
  
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
  
  text: ->
    lines = @get("text").lines()
    lines = for line in lines
      line.trim()
        .replace /^#+\s*(.*)$/mg, "*$1*"
        .replace /^>\s*/mg, ""
    lines.push "    — #{@get("customer") || @get("reporter")?.name}"
    lines.map((line)-> "> #{line}").join("\n")
      .replace /> \n> \n/mg, "> \n"
      .replace /^(> \*.*\*\n)> \n(?!> \*)/mg, "$1"
  
  html: ->
    lines = @get("text").lines()
    lines.push "    — #{@get("customer") || @get("reporter")?.name}"
    text = lines.map((line)-> "> #{line}").join("\n")
    App.mdown(text)
  
  
  
class Houston.Feedback.Comments extends Backbone.Collection
  model: Houston.Feedback.Comment

  countTags: ->
    countByTag = {}
    for comment in @models
      for tag in comment.get('tags')
        countByTag[tag] = (countByTag[tag] ? 0) + 1
    _.sortBy ({tag: tag, count: count} for tag, count of countByTag), (n)-> -n.count
