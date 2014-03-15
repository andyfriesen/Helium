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
        atom.workspaceView.command 'helium:check', => @check()
        atom.workspaceView.command 'helium:get-type', => @getTypeOfThingAtCursor()

    # Returns an object that can be retrieved when package is activated
    serialize: ->

    # Tear down any state and detach
    destroy: ->
        @detach()

    getTypeOfThingAtCursor: ->


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

        range = [[line, col], [line, @editor.lineLengthForBufferRow(line)]]
        preview = @editor.getTextInRange(range)

        AtomMessagePanel.append.lineMessage(line, col, type, preview, 'helium status-notice')
        content.map (m) -> AtomMessagePanel.append.message(m, 'helium error-details')

        @errorLines.push(line)

        @editorView.lineElementForScreenRow(line).addClass(
            if type == 'error' then 'helium-error' else 'helium-warning'
        )

    toggle: ->
        console.log "HeliumView was toggled!"
        if @hasParent()
            @detach()
        else
            atom.workspaceView.append(this)
