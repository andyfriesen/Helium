{BufferedProcess} = require 'atom'
path              = require 'path'
fs                = require 'fs'
temp              = require 'temp'

GHC_MOD_BIN = 'ghc-mod'

module.exports =
    class GhcModTask
        constructor: ({bp, fsmodule, tempmodule})->
            @BufferedProcess = bp ? BufferedProcess
            @fs = fsmodule ? fs
            @temp = tempmodule ? temp
            @onMessage = null
            @queuedRequest = null
            @bp = null
            @buffer = null
            @tempFile = null

        check: ({onMessage, fileName, sourceCode}) ->
            @tempFile = @mkTemp(fileName, sourceCode)

            @run
                command: 'check'
                args: [@tempFile]
                onMessage: (line) =>
                    if matches = /([^:]+):(\d+):(\d+):((?:Warning: )?)(.*)/.exec(line)
                        [_, fileName, line, col, warning, content] = matches
                        type = if warning.length then 'warning' else 'error'
                        pos = [parseInt(line, 10), parseInt(col, 10)]

                        content = content.split('\0').filter((l)-> 0 != l.length)
                        onMessage {type, fileName, pos, content}
                    else
                        console.warn "check got confusing output from ghc-mod:", [line]

        getType: ({onMessage, fileName, sourceCode, pos}) ->
            @tempFile = @mkTemp(fileName, sourceCode)
            @run
                command: 'type'
                args: [@tempFile, 'Main', pos[0] + 1, pos[1] + 1]
                onMessage: (line) =>
                    if matches = /(\d+) (\d+) (\d+) (\d+) "([^"]+)"/.exec(line)
                        [_, startLine, startCol, endLine, endCol, type] = matches
                        onMessage
                            type: type
                            startPos: [parseInt(startLine, 10), parseInt(startCol, 10)]
                            endPos:   [parseInt(endLine, 10), parseInt(endCol, 10)]
                    else
                        console.warn "getType got confusing output from ghc-mod:", [line]

        list: ({onMessage, onComplete}) ->
            @run
                command: 'list'
                args: []
                onMessage: (line) =>
                    onMessage line.trim()
                onComplete: onComplete

        mkTemp: (fileName, contents) ->
            dir = path.dirname(fileName)
            info = @temp.openSync({dir:dir, suffix: '.hs'})
            @fs.writeSync(info.fd, contents, 0, contents.length, 0)
            @fs.closeSync(info.fd)
            return info.path

        run: ({onMessage, onComplete, command, args}) ->
            cmdArgs = args.slice(0)
            cmdArgs.unshift(command)

            if @bp?
                @queuedRequest = {onMessage, command, args}
                return

            @currentRequest = {onMessage, command, args}

            bp_args =
                command: GHC_MOD_BIN
                args: cmdArgs
                stdout: (line) => @stdout(onMessage, line)
                stderr: (line) => @stdout(onMessage, line)
                exit: => @exit(onComplete)

            console.log "Running", bp_args

            @bp = new @BufferedProcess bp_args

        stdout: (onMessage, line) ->
            line.split('\n').filter((l)->0 != l.length).map onMessage

        exit: (onComplete) ->
            onComplete?()

            @bp = null
            @queuedRequest = null
            if @tempFile?
                @fs.unlinkSync(@tempFile)
                @tempFile = null

            return

            if @queuedRequest?
                r = @queuedRequest
                @currentRequest = null
                @run(r)
