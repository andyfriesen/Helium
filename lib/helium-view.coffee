{ Point
, View
} = require 'atom'
{ MessagePanelView
, PlainMessageView
, LineMessageView
} = require 'atom-message-panel'

Parser = require './parse'

module.exports =
class HeliumView
    constructor: (serializeState, ghcModTask) ->
        @ghcModTask = ghcModTask
        @messagePanel = null
        atom.workspaceView.command 'helium:insert-type', => @insertType()

    insertType: ->
        editor = atom.workspace.getActiveEditor()
        return unless editor?

        fileName = editor.getPath()
        cursor = editor.getCursor()
        pos = cursor.getBufferPosition()

        gotFirst = false

        @ghcModTask.getType
            fileName: fileName
            sourceCode: editor.getText()
            pos: [pos.row, pos.column]
            onMessage: (m) =>
                return if gotFirst
                gotFirst = true

                line = editor.getTextInRange(
                    [[pos.row, 0], [pos.row, editor.lineLengthForBufferRow(pos.row)]]
                )

                if matches = /^( *)(\w+) *=(.*)$/.exec(line)
                    editor.transact ->
                        cursor.setBufferPosition(new Point(pos.row, 0))
                        [_, leadingWhitespace, symbolName, definition] = matches
                        newLine = "#{leadingWhitespace}#{symbolName} :: #{m.type}"
                        editor.insertText(newLine)
                        editor.insertNewline()
                        cursor.setBufferPosition(new Point(pos.row + 1, pos.col))
                else if matches = /^( *)(let|where)( +)(\w+)(.*)$/.exec(line)
                    editor.transact ->
                        cursor.setBufferPosition(new Point(pos.row, 0))
                        [_, leadingWhitespace, keyword, moreWhitespace, symbolName, definition] = matches
                        spaces = if keyword == 'let' then '   ' else '     '
                        newLine = "#{leadingWhitespace}#{keyword}#{moreWhitespace}#{symbolName} :: #{m.type}"
                        secondLine = "#{leadingWhitespace}#{spaces}#{moreWhitespace}#{symbolName}#{definition}"
                        editor.insertText(newLine)
                        editor.insertNewline()
                        editor.insertText(secondLine)
                        editor.insertNewline()
                        editor.deleteLine()
                        cursor.setBufferPosition(new Point(pos.row + 1, pos.col))
