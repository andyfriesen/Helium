{View} = require 'atom'
AtomMessagePanel = require 'atom-message-panel'

module.exports =
class HeliumView extends View
    @content: ->
        @div class: 'helium overlay from-top', =>
            @div "The Helium package is Alive! It's ALIVE!", class: "message"

    initialize: (serializeState, ghcModTask) ->
        #atom.workspaceView.command "helium:toggle", => @toggle()
        @ghcModTask = ghcModTask
        @editor = null
        @editorView = null
        @errorLines = []
        @markers = []
        atom.workspaceView.command 'helium:check', => @check()
        atom.workspaceView.command 'helium:get-type', => @getTypeOfThingAtCursor()
        atom.workspaceView.command 'helium:insert-type', => @insertType()

    # Returns an object that can be retrieved when package is activated
    serialize: ->

    # Tear down any state and detach
    destroy: ->
        @detach()

    insertType: ->
        editor = atom.workspace.getActiveEditor()
        return unless editor?

        fileName = editor.getPath()
        cursor = editor.getCursor()
        pos = cursor.getBufferPosition()

        gotFirst = false

        @ghcModTask.getType
            fileName: fileName
            pos: [pos.row, pos.column]
            onMessage: (m) =>
                return if gotFirst
                gotFirst = true

                line = editor.getTextInRange(
                    [[pos.row, 0], [pos.row, editor.lineLengthForBufferRow(pos.row)]]
                )

                if matches = /^( *)(\w+) *=(.*)$/.exec(line)
                    editor.transact ->
                        cursor.setBufferPosition([pos.row, 0])
                        [_, leadingWhitespace, symbolName, definition] = matches
                        newLine = "#{leadingWhitespace}#{symbolName} :: #{m.type}"
                        editor.insertText(newLine)
                        editor.insertNewline()
                        cursor.setBufferPosition([pos.row + 1, pos.col])
                else if matches = /^( *)(let|where)( +)(\w+)(.*)$/.exec(line)
                    editor.transact ->
                        cursor.setBufferPosition([pos.row, 0])
                        [_, leadingWhitespace, keyword, moreWhitespace, symbolName, definition] = matches
                        spaces = if keyword == 'let' then '   ' else '     '
                        newLine = "#{leadingWhitespace}#{keyword}#{moreWhitespace}#{symbolName} :: #{m.type}"
                        secondLine = "#{leadingWhitespace}#{spaces}#{moreWhitespace}#{symbolName}#{definition}"
                        editor.insertText(newLine)
                        editor.insertNewline()
                        editor.insertText(secondLine)
                        editor.insertNewline()
                        editor.deleteLine()
                        cursor.setBufferPosition([pos.row + 1, pos.col])

    getTypeOfThingAtCursor: ->
        editor = atom.workspace.getActiveEditor()
        return unless editor?

        fileName = editor.getPath()
        pos = editor.getCursor().getBufferPosition()
        console.log 'pos', pos

        gotTheFirstOne = false

        @ghcModTask.getType
            fileName: fileName
            pos: [pos.row, pos.column]
            onMessage: (m) =>
                console.log "getType", m
                if !gotTheFirstOne
                    AtomMessagePanel.destroy()
                    AtomMessagePanel.init('GHC TypeInfo')
                gotTheFirstOne = true
                expr = editor.getTextInRange(
                    [ [ m.startPos[0] - 1, m.startPos[1] - 1 ]
                    , [ m.endPos[0] - 1, m.endPos[1] - 1]
                    ]
                )
                AtomMessagePanel.append.message("<span class=\"code\">#{expr}</span><span class=\"type\">#{m.type}", "helium-typeinfo")

    check: ->
        editor = atom.workspace.getActiveEditor()
        editorView = atom.workspaceView.getActiveView()
        fileName = editor?.getPath()

        if fileName? and editor? and editorView?
            @clear()
            @editor = editor
            @editorView = editorView

            AtomMessagePanel.init('GHC')

            @ghcModTask.check
                onMessage: (m) => @onMessage(m)
                fileName: fileName

    clear: ->
        AtomMessagePanel.destroy()
        @errorLines.map (l) =>
            @editorView.lineElementForScreenRow(l).removeClass('helium-error helium-warning')
        @errorLines.splice(0)

    onMessage: (message) ->
        console.log "onMessage", message
        type = message.type
        [line, col] = message.pos
        content = message.content

        range = [[line - 1, 0], [line - 1, @editor.lineLengthForBufferRow(line - 1)]]
        preview = @editor.getTextInRange(range)

        AtomMessagePanel.append.lineMessage(line, col, type, preview, 'helium status-notice')
        content.map (m) -> AtomMessagePanel.append.message(m, 'helium error-details')

        @errorLines.push(line - 1)

        @editorView.lineElementForScreenRow(line - 1).addClass(
            if type == 'error' then 'helium-error' else 'helium-warning'
        )

    toggle: ->
        console.log "HeliumView was toggled!"
        if @hasParent()
            @detach()
        else
            atom.workspaceView.append(this)
