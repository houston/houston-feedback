# Inspired by Medium
# Adapted from djyde.github.io/WebClip

class @SelectionToolbar

  constructor: (@el) ->
    @plugins = []
    @selectedContent = null
    @selection = null
    @toolbar = null

    @_blurListener = (e) =>
      @hideToolbar()

    @_mousedownListener = (e) =>
      # if selectedContent exists when mousedown, it should do nothing but cancel selecting
      return false if @selectedContent

    @_mouseupListener = (e) =>
      delay =>
        @selection = window.getSelection()
        @selectedContent = @selection.toString()
        if @selection.type is "Range"
          range = @selection.getRangeAt(0).cloneRange()
          rect = range.getBoundingClientRect()
          @showToolbar(rect)
        else
          @hideToolbar()

    @el.addEventListener "blur", @_blurListener
    @el.addEventListener "mousedown", @_mousedownListener
    @el.addEventListener "mouseup", @_mouseupListener

  destroy: ->
    @el.removeEventListener "blur", @_blurListener
    @el.removeEventListener "mousedown", @_mousedownListener
    @el.removeEventListener "mouseup", @_mouseupListener
    @toolbar.remove() if @toolbar

  use: (plugin) ->
    if Array.isArray(plugin)
      @plugins = plugin
    else
      @plugins.push(plugin)

  showToolbar: (rect, range) ->
    # toolbar element only create once
    @toolbar = createToolbar.call(@) unless @toolbar
    @toolbar.style.display = ""
    @toolbar.style.opacity = "1"

    # caculate the position of toolbar
    toolbarWidth = @toolbar.offsetWidth
    toolbarHeight = @toolbar.offsetHeight
    @toolbar.style.left = "#{(rect.right - rect.left) / 2 + rect.left - toolbarWidth / 2}px"
    @toolbar.style.top = "#{rect.top - toolbarHeight - 4 + document.body.scrollTop}px"

  hideToolbar: ->
    return unless @toolbar
    @toolbar.style.opacity = "0"
    delay => @toolbar.style.display = "none"


createToolbar = (parent, plugins) ->
  toolbar = document.createElement("ul")

  # add class for toolbarbar
  toolbar.classList.add "selection-toolbar"

  @plugins.map (plugin) =>
    item = document.createElement("li")
    item.classList.add "selection-toolbar-item"
    item.setAttribute "title", plugin.description or plugin.name

    if plugin.icon
      fa = document.createElement("i")
      item.classList.add "selection-toolbar-icon", "fa", "fa-#{plugin.icon}"
      item.appendChild fa
    else
      item.textContent = plugin.name

    # add onclick event listener with `action` action
    item.addEventListener "click", (e) =>
      plugin.action @selectedContent, @selection.getRangeAt(0).cloneRange()

    toolbar.appendChild item

  document.body.appendChild toolbar


delay = (fn) ->
  setTimeout fn, 100
