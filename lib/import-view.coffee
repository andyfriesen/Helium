{$$, Point, SelectListView} = require 'atom'
Parser = require './parse'

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

        p = new Parser(@editor.getText())
        d = p.moduleDecl()

        if d?
            position = [p.line + 1, 0]
        if not d?
            p.eatWhitespace()
            position = [p.line, 0]

        cursor.setBufferPosition(position)

        @editor.insertText("import " + item + '\n')
        cursor.setBufferPosition(new Point(pos.row + 1, pos.column))
        @editor.commitTransaction()

    selectNextItemView: ->
        super
        false

    selectPreviousItemView: ->
        super
        false
