_ = require 'underscore-plus'

# Manage a set of views and their attachments to all open editors.
module.exports =
class ViewManager
    constructor: (factory) ->
        @factory = factory
        @subscription = null
        @views = []

    activate: (state) ->
        @subscription = atom.workspaceView.eachEditorView (editor) =>
            view = @factory(editor)
            editor.on 'editor:will-be-removed', =>
                view.remove() unless view.hasParent()
                _.remove @views, view
            @views.push(view)

    deactivate: ->
        @subscription?.off()
        @views.map (v) -> v.remove()
        @views.splice 0
