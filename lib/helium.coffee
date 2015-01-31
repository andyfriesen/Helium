{ Point } = require 'atom'
{ View } = require 'atom-space-pen-views'

{ MessagePanelView
, PlainMessageView
} = require 'atom-message-panel'

path = require 'path'

CompilerMessageView = require './compiler-message-view'
ImportView  = require './import-view'
GhcModTask  = require './ghc-mod-task'
ViewManager = require './view-manager'

{ findEditor
} = require './util'

module.exports =
    messagePanel: null
    importViewManager: null

    activate: (state) ->
        @ghcModTask = new GhcModTask({})

        atom.workspace.observeTextEditors(
            (editor) => new ImportView(@ghcModTask, editor)
        )

        @markers = []

        atom.commands.add 'atom-workspace', 'helium:check', => @check()
        atom.commands.add 'atom-workspace', 'helium:get-type', => @getTypeOfThingAtCursor()
        atom.commands.add 'atom-workspace', 'helium:insert-type', => @insertType()

    deactivate: ->
        @heliumView.destroy()
        @importViewManager.deactivate()

    serialize: ->
        heliumViewState: @heliumView.serialize()

    check: ->
        editor = atom.workspace.getActiveTextEditor()
        fileName = editor?.getPath()

        if not fileName? or not editor?
            return

        @clear()

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
                [line, column] = message.pos
                bufferLine = line - 1
                bufferCol = column - 1
                displayFileName = path.relative(atom.project.getPath(), fileName)

                preview = ''
                findEditor message.fileName, (pane, index, item) =>
                    range = [[bufferLine, 0], [bufferLine, item.lineTextForBufferRow(bufferLine).length]]
                    preview = item.getTextInRange(range)

                if message.fileName == editor.getPath()
                    textBuffer = editor.getBuffer()
                    marker = editor.markBufferRange [[bufferLine, bufferCol], [bufferLine, textBuffer.lineLengthForRow bufferLine]]
                    @markers.push(marker)
                    editor.decorateMarker(marker, {
                        'type': 'highlight',
                        'class': if type == 'error' then 'helium-error' else 'helium-warning'
                    })

                @messagePanel.add(
                    new CompilerMessageView
                        line: line
                        column: column
                        fileName: fileName
                        displayFileName: displayFileName
                        message: type
                        preview: preview
                        className: 'helium status-notice'
                )

                content.map (m) => @messagePanel.add(
                    new PlainMessageView
                        message: m
                        className: 'helium error-details'
                )

    clear: () ->
        @messagePanel?.detach()
        @messagePanel = null

        for m in @markers
            m.destroy()
        @markers.splice(0)

    getTypeOfThingAtCursor: ->
        editor = atom.workspace.getActiveTextEditor()
        return unless editor?

        fileName = editor.getPath()
        pos = editor.getLastCursor().getBufferPosition()

        gotTheFirstOne = false

        @ghcModTask.getType
            fileName: fileName
            sourceCode: editor.getText()
            pos: [pos.row, pos.column]
            onMessage: (m) =>
                if !gotTheFirstOne
                    @messagePanel?.detach()
                    @messagePanel = new MessagePanelView
                        title: 'GHC TypeInfo'
                    @messagePanel.attach()

                gotTheFirstOne = true
                expr = editor.getTextInRange(
                    [ [ m.startPos[0] - 1, m.startPos[1] - 1 ]
                    , [ m.endPos[0] - 1, m.endPos[1] - 1]
                    ]
                )

                @messagePanel.add(
                    new PlainMessageView
                        message:   "<span class=\"code\">#{expr}</span><span class=\"type\">#{m.type}"
                        raw: true
                        className: "helium-typeinfo"
                )

    insertType: ->
        editor = atom.workspace.getActiveTextEditor()
        return unless editor?

        fileName = editor.getPath()
        cursor = editor.getLastCursor()
        pos = cursor.getBufferPosition()

        gotFirst = false

        @ghcModTask.getType
            fileName: fileName
            sourceCode: editor.getText()
            pos: [pos.row, pos.column]
            onMessage: (m) =>
                return if gotFirst
                gotFirst = true

                line = editor.lineTextForBufferRow(pos.row)

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
                        console.log 'matches', [leadingWhitespace.length, keyword, moreWhitespace.length, symbolName, definition]
                        spaces = if keyword == 'let' then '   ' else '     '
                        newLine = "#{leadingWhitespace}#{keyword}#{moreWhitespace}#{symbolName} :: #{m.type}"
                        secondLine = "#{leadingWhitespace}#{spaces}#{moreWhitespace}#{symbolName}#{definition}"
                        console.log 'secondLine', {foo:secondLine}
                        editor.insertText(newLine)
                        editor.insertText('\n', {autoIndentNewline: false})
                        editor.insertText(secondLine)
                        editor.insertNewline()
                        editor.deleteLine()
                        cursor.setBufferPosition(new Point(pos.row + 1, pos.column))
