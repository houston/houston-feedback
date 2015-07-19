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
    
    # Replace H_ tags with bold text of the same font size
    # and get rid of inner quotes.
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

    # Replace H_ tags with bold text of the same font size
    # and get rid of inner quotes.
    lines = for line in lines
      line.trim()
        .replace /^#+\s*(.*)$/mg, "**$1**\n"
        .replace /^>\s*/mg, ""

    """
    <p style="margin: 0; padding: 0;">&nbsp;</p>
    <div style="font-family: 'Helvetica Neue', roboto, Helvetica, Arial, sans-serif; padding: 1em;">
      <h3 style="font-weight: normal; font-size: 1.25em; line-height: 1em; padding: 0; margin: 0;">#{@get("customer") || @get("reporter")?.name}</h3>
      <div style="font-size: 0.92em; line-height: 1em; padding: 0; margin: 0; color: #888;">#{@get("reporter")?.name} • #{Handlebars.helpers.formatDateWithYear2 @get("createdAt")}</div>
      <div style="border-left: 5px solid #ddd; padding-left: 0.66em; margin: 0;">#{App.mdown(lines.join("\n"))}</div>
    </div>
    <p style="margin: 0; padding: 0;">&nbsp;</p>
    """
  
  
  
class Houston.Feedback.Comments extends Backbone.Collection
  model: Houston.Feedback.Comment

  countTags: ->
    countByTag = {}
    for comment in @models
      for tag in comment.get('tags')
        countByTag[tag] = (countByTag[tag] ? 0) + 1
    _.sortBy ({tag: tag, count: count} for tag, count of countByTag), (n)-> -n.count
