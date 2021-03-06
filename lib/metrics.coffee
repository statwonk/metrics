crypto = require 'crypto'
Reporter = require './reporter'

module.exports =
  activate: ({sessionLength}) ->
    if atom.config.get('metrics.userId')
      @begin(sessionLength)
    else
      @getUserId (userId) -> atom.config.set('metrics.userId', userId)
      @begin(sessionLength)

  serialize: ->
    sessionLength: Date.now() - @sessionStart

  begin: (sessionLength) ->
    @sessionStart = Date.now()

    Reporter.sendEvent('window', 'ended', sessionLength) if sessionLength
    Reporter.sendEvent('window', 'started')
    atom.workspaceView.on 'pane:item-added', (event, item) ->
      Reporter.sendPaneItem(item)

    if atom.getLoadSettings().shellLoadTime?
      # Only send shell load time for the first window
      Reporter.sendTiming('shell', 'load', atom.getLoadSettings().shellLoadTime)

    process.nextTick ->
      # Wait until window is fully bootstrapped before sending the load time
      Reporter.sendTiming('core', 'load', atom.getWindowLoadTime())

  getUserId: (callback) ->
    require('getmac').getMac (error, macAddress) =>
      if error?
        callback require('guid').raw()
      else
        callback crypto.createHash('sha1').update(macAddress, 'utf8').digest('hex')
