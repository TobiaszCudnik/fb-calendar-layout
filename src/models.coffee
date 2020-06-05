compare = require 'compare-property'
assert = require './assert'



class DayModel
  ###*
   * Collection of all events fir this day.
   * @type {EventCollection}
  ###
  events: null
  ###*
   * Number of hours to show starting from the #start_hour.
   * @type {number}
  ###
  hours: null
  ###*
   * Height of one hour.
   * @type {number} In pixels.
  ###
  hour_height: null
  ###*
   * Base hour for the events.
   * @type {number} In pixels.
  ###
  start_hour: null


  constructor: (@hours, @hour_height, @start_hour) ->
    @events = new EventCollection
    assert @hours
    assert @hour_height
    assert @start_hour


class EventModel
  ###*
   * Start of the event, measured in minutes since the parent
   * DayModel#start_hour.
   *
   * @type {number}
  ###
  start: null
  ###*
   * End of the event, measured in minutes since the parent
   * DayModel#start_hour.
   *
   * @type {number}
  ###
  end: null
  ###*
   * References to all event which collide in time with this event.
   *
   * @type {Array.<EventModel>}
  ###
  adjacents: null
  ###*
   * References to all event which collide in time with this event and
   * each other as well. Subset of all adjacents.
   *
   * @type {Array.<EventModel>}
  ###
  line_group: null
  ###*
   * Temporary ID, used to identify the event in the current collection
   * (needed for proper rendering).
  ###
  id: null


  ###*
   * Event model constructor.
   *
   * @param data {{start: number, end: number}} Event's data
   * @param id {number} Temporary ID, used to identify the event in the current
   *   collection (needed for proper rendering)
  ###
  constructor: (data, @id) ->
    @parse data
    assert typeof @id is 'number'

    @adjacents = []
    @line_group = []


  parse: (data) ->
    assert typeof data.start is 'number'
    assert typeof data.end is 'number'
    assert data.end > data.start, "End have to be higher than start"

    @start = data.start
    @end = data.end


  ###*
   * Gets maximum number of events in line groups
  ###
  getMaxLineAdjacentsCount: ->
    max_group = Math.max.apply Math, [@line_group.length].concat(
      @traverseAdjacents (event) -> event.line_group.length
    )

    # groups dont include the relative event, so we need it include it manually
    max_group + 1


  ###*
   * Traverse the adjacents graph, starting from the adjaents of the current
   * event. Function fn is executed on each element only once.
   *
   * @param fn {function(EventModel)}
  ###
  traverseAdjacents: (fn) ->
    visited = {}
    visited[@id] = yes
    queue = @adjacents
    ret = []

    while queue.length
      event = queue.pop()
      continue if visited[event.id]
      visited[event.id] = yes
      queue = queue.concat event.adjacents
      ret.push fn event

    ret


class EventCollection
  ###*
   * @type {Array.<EventModel>}
  ###
  models: null
  ###*
   * Events sort comparator.
   *
   * @type {function(a: Object, b: Object): number}
  ###
  comparator: null


  constructor: ->
    # sorts by 'start' ASC and by 'end' DESC
    @comparator = compare.properties start: 1, end: -1
    @models = []


  set: (events) ->
    assert events
    @models = events.map (data, index) =>
      existing = @getByTime data.start, data.end

      # reuse an existing model if already present in the collection
      if existing
        # update the temporary id
        existing.id = index

        return existing

      new EventModel data, index

    @buildGraph()


  getByTime: (start, end) ->
    for model in @models
      if model.start is start and model.end is end
        return model


  buildGraph: ->
    assert @comparator

    @calculateAdjacents()
    @calculateLineGroups()


  ###*
   * Calculates all the adjacents of the event, which means all the events
   * colliding in time.
  ###
  calculateAdjacents: ->
    # sort by 'start' ASC and by 'end' DESC
    @models.sort @comparator

    # find all adjacents of the events
    for event, id in @models

      # TODO optimise, start iteration from the first (in order) event which has
      #   the same 'start' as the current one
      for adjacent in @models
        continue if adjacent is event

        if adjacent.start < event.end and adjacent.end > event.start
          event.adjacents.push adjacent

        # stop iteration if reached time after this event (its sorted)
        break if adjacent.start >= event.end


  ###*
   * Calculates the line group, in which events all collide in time with each
   * other. Used to determine the width of the event box.
  ###
  calculateLineGroups: ->
    # build one line group for every event
    for event in @models
      # start with an empty grouppa
      line_group = []

      # check every adjacent if it qualifies for a group
      for adjacent in event.adjacents

        # which it does when its an adjacent of every group event
        same_line = line_group.every (previous) ->
          ~previous.adjacents.indexOf adjacent

        if same_line
          line_group.push adjacent

      event.line_group = line_group



module.exports = {
  DayModel
  EventModel
  EventCollection
}
