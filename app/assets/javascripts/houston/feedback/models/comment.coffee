class Houston.Feedback.Comment extends Backbone.Model
  urlRoot: '/feedback/comments'

class Houston.Feedback.Comments extends Backbone.Collection
  model: Houston.Feedback.Comment
