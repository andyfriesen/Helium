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
        atom.workspaceView.command 'helium:check', => @check()

    # Returns an object that can be retrieved when package is activated
    serialize: ->

    # Tear down any state and detach
    destroy: ->
        @detach()

    check: ->
        @editor = atom.workspace.getActiveEditor()
        @editorView = atom.workspaceView.getActiveView()
        fileName = @editor?.getPath()

        if fileName? and @editor? and @editorView?
            AtomMessagePanel.init('GHC')

            @ghcModTask.run
                onMessage: (m) => @onMessage(m)
                fileName: fileName

    onMessage: (message) ->
        type = message.type
        [line, col] = message.pos
        content = message.content

        range = [[line - 1, col - 1], [line - 1, @editor.lineLengthForBufferRow(line - 1)]]
        preview = @editor.getTextInRange(range)

        AtomMessagePanel.append.lineMessage(line, col, type, preview, 'helium status-notice')
        content.map (m) -> AtomMessagePanel.append.message(m, 'helium error-details')

        @editorView.lineElementForScreenRow(line - 1).addClass(
            if type == 'error' then 'helium-error' else 'helium-warning'
        )

    toggle: ->
        console.log "HeliumView was toggled!"
        if @hasParent()
            @detach()
        else
            atom.workspaceView.append(this)
