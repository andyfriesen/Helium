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
        atom.workspaceView.command 'helium:check', => @check()
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

    check: ->
        editor = atom.workspace.getActiveEditor()
        editorView = atom.workspaceView.getActiveView()
        fileName = editor?.getPath()

        if fileName? and editor? and editorView?
            @clear(editorView)

            @messagePanel?.detach()
            @messagePanel = new MessagePanelView
                title: 'GHC'

            @messagePanel.attach()

            @ghcModTask.check
                fileName: fileName
                sourceCode: editor.getText()
                onMessage: (message) =>
                    console.log "onMessage", message
                    {type, content, fileName} = message
                    [line, col] = message.pos

                    if message.fileName == editor.getPath()
                        range = [[line - 1, 0], [line - 1, editor.lineLengthForBufferRow(line - 1)]]
                        preview = editor.getTextInRange(range)

                        message = type
                        className = 'helium status-notice'

                        @messagePanel.add(
                            new LineMessageView { line, col, fileName, message, preview, className }
                        )

                        content.map (m) => @messagePanel.add(new PlainMessageView { message: m, className: 'helium error-details' })

                        editorView.lineElementForScreenRow(line - 1).addClass(
                            if type == 'error' then 'helium-error' else 'helium-warning'
                        )

                    else
                        @messagePanel.add(
                            new LineMessageView
                                line: line
                                character: col
                                fileName: fileName
                                message: type
                                # message: "#{line}:#{col} of #{fileName}"
                                className: 'helium status-notice'
                        )

                        content.map (m) => @messagePanel.add(new PlainMessageView {message: m, className: 'helium error-details'})

    clear: (editorView) ->
        @messagePanel?.detach()
        @messagePanel = null

        editorView.find('.helium-error').removeClass('helium-error')
        editorView.find('.helium-warning').removeClass('helium-warning')
