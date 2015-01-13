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
  
  
class Houston.Feedback.Comments extends Backbone.Collection
  model: Houston.Feedback.Comment
