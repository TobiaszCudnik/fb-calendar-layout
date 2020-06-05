{
  DayModel
  EventModel
  EventCollection
} = require './models'
assert = require './assert'



class View
  container: null
  node: null
  disposed: null
  ###*
   * Model for this view. Optional.
   *
   * @type {?Object}
  ###
  model: null
  rendered: null


  constructor: (@container, @model = null) ->
    assert @container
    @rendered = no


  dispose: ->
    @container?.removeChild @node
    @disposed = yes
    @rendered = no


  render: ->
    throw new Error 'abstract'


class EventView extends View
  max_width: null
  ###*
   * @type {EventModel}
   * @override
  ###
  model: null


  constructor: (container, model, @max_width, @padding_left) ->
    super container, model
    assert model
    assert @max_width
    assert @padding_left


  getWidth: ->
    # prevent collapsing by flooring the width
    # TODO check
    Math.floor @max_width / @model.getMaxLineAdjacentsCount()


  getLeft: (width, rendered_events) ->
    left = 0
    for adjacent in @model.line_group
      rendered_left = rendered_events[adjacent.id]
      # shift by already rendered adjacents, but only if there's no gap
      if rendered_left? and rendered_left != (left + width)
        left += width

    left


  render: (rendered_events) ->
    # preserve the previous node if any
    if not @rendered
      @node = document.createElement 'li'
      @renderBorder()
      @renderContent()

    @setPosition rendered_events

    if not @rendered
      @container.appendChild @node
    @rendered = yes


  renderBorder: ->
    assert @node
    @node.appendChild document.createElement 'span'


  ###*
   * TODO support updating the content to existing nodes
   * TODO support content from the event data
  ###
  renderContent: ->
    assert @node

    container = document.createElement 'div'

    header = document.createElement 'h6'
    header.textContent = 'Sample Item'
    container.appendChild header

    content = document.createElement 'p'
    content.textContent = 'Sample Location'
    container.appendChild content

    @node.appendChild container


  setPosition: (rendered_events) ->
    width = @getWidth()
    @node.style.width = "#{width}px"
    @node.style.height = @model.end - @model.start + 'px'
    left = @getLeft width, rendered_events
    @node.style.left = "#{@padding_left + left}px"
    @node.style.top = @model.start + 'px'

    # memorize the left edge position
    rendered_events[@model.id] = left

    left


class DayView extends View
  ###*
   * @type {DOMElement}
  ###
  sidebar_node: null
  ###*
   * @type {DOMElement}
  ###
  events_node: null
  ###*
   * @type {Array.<EventView>}
  ###
  event_views: null
  ###*
   * Rendered events indexed by ID and their left edge position.
   *
   * @type {Object.<number, number>}
  ###
  rendered_events: null
  ###*
   * @type {number}
  ###
  max_event_width: null
  ###*
   * @type {DayModel}
   * @override
  ###
  model: null


  constructor: (container, model, @max_event_width, @padding_left) ->
    super
    assert model

    @sidebar_node = @container.querySelector '.sidebar'
    assert @sidebar_node

    @events_node = @container.querySelector '.events'
    assert @events_node


  render: ->
    @rendered_events = {}
    reuseViews = @disposeOldEventViews()

    @event_views = @model.events.models.map (model) =>
      if reuseViews[model.id]
        return reuseViews[model.id]

      new EventView @events_node, model, @max_event_width, @padding_left

    @renderSidebar()
    # TODO DOM appends could be done in bulk here
    for event in @event_views
      event.render @rendered_events

    @rendered = yes


  ###*
   * Dispose not needed event views and index the ones to reuse by model ID.
   *
   * @return {Object.<number, boolean>}
  ###
  disposeOldEventViews: ->
    reuseViews = {}

    for view in @event_views or []
      if not ~@model.events.models.indexOf view.model
        view.dispose()
      else
        reuseViews[view.model.id] = view

    reuseViews


  renderSidebar: ->
    # render the sidebar only once
    return if @rendered

    # 2 steps per hour, as we need to render *:30 as well
    # iterate twice per an hour, creating the expected format
    for step in [0..@model.hours*2]
      # full hour
      hour = if step % 2 is 0
        step * 50
        # half past
      else
        # shift halfs to hour-like (parseInt would be the correct way probably)
        step * 50-20

      @renderSidebarStep hour + @model.start_hour * 100


  ###*
   * Renders the sidebar nodes.
   *
   * @param hour {Number} Hour in format "1200" or "930".
  ###
  renderSidebarStep: (hour) ->
    node = document.createElement 'li'

    # AM / PM suffix for full hours
    if hour % 100 is 0
      suffix = if hour >= 1200 then 'PM' else 'AM'
      suffix_node = document.createElement 'span'
      suffix_node.textContent = suffix

    # 16:00 to 4:00
    if hour >= 1300
      hour -= 1200

    # insert the text with a colon
    hour = hour.toString()
    node.textContent = "#{hour[0...-2]}:#{hour[-2..-1]}"
    node.appendChild suffix_node if suffix_node
    @sidebar_node.appendChild node



module.exports = {
  View
  EventView
  DayView
}
