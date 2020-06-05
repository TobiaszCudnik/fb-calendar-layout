"use strict"

assert = require './assert'
#require('source-map-support').install()
{ DayModel } = require './models'
{ DayView } = require './views'


config =
  width: 600
  padding_left: 10
  hours: 12
  hour_height: 60
  start_hour: 9


# singleton
app = null
document.addEventListener 'DOMContentLoaded', ->
  app = new Main config, document.querySelector 'section.day'
  app.render()
  app.setData [
    {start: 30, end: 150}
    {start: 540, end: 600}
    {start: 560, end: 620}
    {start: 610, end: 670}
  ]


layOutDay = (data) ->
  assert app, "Data set before the DOM loaded event"
  app.setData data


class Main
  config: null
  day_view: null


  constructor: (@config, container) ->
    assert @config
    assert container

    day_model = new DayModel @config.hours, @config.hour_height,
      @config.start_hour

    @day_view = new DayView container, day_model, @config.width,
      @config.padding_left


  setData: (data) ->
    @day_view.model.events.set data
    @day_view.render()


  render: ->
    @day_view.render()



# global export
window.layOutDay = layOutDay
