{BufferedProcess} = require 'atom'

ghc_bin = 'ghc-mod'

module.exports =
    class GhcModTask
        constructor: ({bp})->
            @BufferedProcess = bp ? BufferedProcess
            @onMessage = null
            @queuedRequest = null
            @bp = null
            @buffer = null

        check: ({onMessage, fileName}) ->
            @run
                command: 'check'
                args: [fileName]
                onMessage: (line) =>
                    if matches = /([^:]+):(\d+):(\d+):((?:Warning: )?)(.*)/.exec(line)
                        [_, fileName, line, col, warning, content] = matches
                        type = if warning.length then 'warning' else 'error'
                        pos = [parseInt(line, 10) - 1, parseInt(col, 10) - 1]

                        content = content.split('\0').filter((l)-> 0 != l.length)
                        onMessage {type, fileName, pos, content}
                    else
                        console.warn "check got confusing output from ghc-mod:", [line]

        getType: ({onMessage, fileName, pos}) ->
            @run
                command: 'type'
                args: [fileName, 'Main', pos[0] + 1, pos[1] + 1]
                onMessage: (line) =>
                    if matches = /(\d+) (\d+) (\d+) (\d+) "([^"]+)"/.exec(line)
                        [_, startLine, startCol, endLine, endCol, type] = matches
                        onMessage
                            type: type
                            startPos: [parseInt(startLine, 10), parseInt(startCol, 10)]
                            endPos:   [parseInt(endLine, 10), parseInt(endCol, 10)]
                    else
                        console.warn "getType got confusing output from ghc-mod:", [line]

        run: ({onMessage, command, args}) ->
            cmdArgs = args.slice(0)
            cmdArgs.unshift(command)

            if @bp?
                @queuedRequest = {onMessage, command, args}
                return

            @currentRequest = {onMessage, command, args}

            bp_args =
                command: ghc_bin
                args: cmdArgs
                stdout: (line) => @stdout(onMessage, line)
                stderr: (line) => @stdout(onMessage, line)
                exit: => @exit()

            console.log "Running", bp_args

            @bp = new @BufferedProcess bp_args

        stdout: (onMessage, line) ->
            line.split('\n').filter((l)->0 != l.length).map onMessage

        exit: ->
            @bp = null
            @queuedRequest = null
            return

            if @queuedRequest?
                r = @queuedRequest
                @currentRequest = null
                @run(r)
