{ Point
, View
} = require 'atom'

{ MessagePanelView
, PlainMessageView
, LineMessageView
} = require 'atom-message-panel'

Parser = require './parse'

HeliumView = require './helium-view'
ImportView = require './import-view'
GhcModTask = require './ghc-mod-task'
ViewManager = require './view-manager'

module.exports =
    heliumView: null
    messagePanel: null
    importViewManager: null

    activate: (state) ->
        @ghcModTask = new GhcModTask({})
        @heliumView = new HeliumView(state.heliumViewState, @ghcModTask)

        @importViewManager = new ViewManager (editor) => new ImportView(@ghcModTask, editor)
        @importViewManager.activate()

        atom.workspaceView.command 'helium:get-type', => @getTypeOfThingAtCursor()

    deactivate: ->
        @heliumView.destroy()
        @importViewManager.deactivate()

    serialize: ->
        heliumViewState: @heliumView.serialize()

    getTypeOfThingAtCursor: ->
        editor = atom.workspace.getActiveEditor()
        return unless editor?

        fileName = editor.getPath()
        pos = editor.getCursor().getBufferPosition()

        p = new Parser(editor.getText())
        decl = p.moduleDecl()

        moduleName = if decl? then decl.moduleName else 'Main'

        gotTheFirstOne = false

        @ghcModTask.getType
            fileName: fileName
            moduleName: moduleName
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
