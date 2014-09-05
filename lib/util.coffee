
module.exports =
    findEditor: (pathName, onFound, onNotFound) ->
        for pane in atom.workspace.getPanes()
            for item, index in pane.getItems()
                if item.getPath?() == pathName
                    onFound(pane, index, item)

        onNotFound?()

    isSamePath: (a, b) ->
        if process.platform == 'win32'
            a.toLowerCase() == b.toLowerCase()
        a == b
