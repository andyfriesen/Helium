HeliumView = require './helium-view'
GhcModTask = require './ghc-mod-task'

module.exports =
  heliumView: null

  activate: (state) ->
      @ghcModTask = new GhcModTask({})
      @heliumView = new HeliumView(state.heliumViewState, @ghcModTask)

  deactivate: ->
      @heliumView.destroy()

  serialize: ->
      heliumViewState: @heliumView.serialize()
