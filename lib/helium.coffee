HeliumView = require './helium-view'
ImportView = require './import-view'
GhcModTask = require './ghc-mod-task'
ViewManager = require './view-manager'

module.exports =
    heliumView: null
    importViewManager: []

    activate: (state) ->
        @ghcModTask = new GhcModTask({})
        @heliumView = new HeliumView(state.heliumViewState, @ghcModTask)

        @importViewManager = new ViewManager (editor) => new ImportView(@ghcModTask, editor)
        @importViewManager.activate()

    deactivate: ->
        @heliumView.destroy()
        @importViewManager.deactivate()

    serialize: ->
        heliumViewState: @heliumView.serialize()
