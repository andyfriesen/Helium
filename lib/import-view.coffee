{SelectListView, $$} = require 'atom'

module.exports =
class ImportView extends SelectListView
    initialize: (ghcModTask, editorView) ->
        super

        @addClass 'autocomplete popover-list'

        @ghcModTask = ghcModTask
        @editorView = editorView
        @editor = editorView.getEditor()

        @editorView.command 'helium:insert-import', =>
            if @hasParent()
                @cancel()
            else
                @attach()

    attach: ->
        @editor.beginTransaction()
        @editorView.appendToLinesView(this)
        @focusFilterEditor()
        @computeImports()

    viewForItem: (item) ->
        "<li>#{item}</li>"

    computeImports: ->
        modules = []
        @ghcModTask.list
            onMessage: (module) ->
                modules.push module
            onComplete: =>
                @setItems modules

    confirmed: (item) ->
        @cancel()
        cursor = @editor.getCursor()
        pos = cursor.getBufferPosition()

        cursor.setBufferPosition([0, 0]) # FIXME: This is so wrong that it is useless

        @editor.insertText("import " + item + '\n')
        cursor.setBufferPosition([pos[0] + 1, pos[1]])
        @editor.commitTransaction()

    selectNextItemView: ->
        super
        false

    selectPreviousItemView: ->
        super
        false
