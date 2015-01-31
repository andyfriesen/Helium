{Point, workspaceView} = require 'atom'
{$$, SelectListView} = require 'atom-space-pen-views'
Parser = require './parse'

module.exports =
class ImportView extends SelectListView
    initialize: (ghcModTask, textEditor) ->
        super

        @addClass 'autocomplete popover-list'

        @ghcModTask = ghcModTask
        @textEditor = textEditor
        # @editor = textEditor.getEditor()

        # @textEditor.command 'helium:insert-import', =>
        #     if @hasParent()
        #         @cancel()
        #     else
        #         @attach()

    attach: ->
        workspaceView.append(this)
        # @editor.beginTransaction()
        # @textEditor.appendToLinesView(this)
        # @focusFilterEditor()
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
        pos = @textEditor.getCursorBufferPosition()

        p = new Parser(@editor.getText())
        d = p.moduleDecl()

        if d?
            position = [p.line + 1, 0]
        if not d?
            p.eatWhitespace()
            position = [p.line, 0]

        # cursor.setBufferPosition(position)
        @textEditor.setCursorBufferPosition(position)

        @textEditor.insertText("import " + item + '\n')
        # cursor.setBufferPosition(new Point(pos.row + 1, pos.column))
        @textEditor.setCursorBufferPosition(new Point(pos.row + 1, pos.column))
        # @editor.commitTransaction()

    selectNextItemView: ->
        super
        false

    selectPreviousItemView: ->
        super
        false
