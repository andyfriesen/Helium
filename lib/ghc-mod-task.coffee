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
            @run({
                onMessage: onMessage,
                command: 'check',
                args: [fileName]
            })

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
                stdout: (line) => @stdout(line)
                stderr: (line) => @stdout(line)
                exit: => @exit()

            console.log "Running", bp_args

            @bp = new @BufferedProcess bp_args

        stdout: (line) ->
            line.split('\n').map @processLine.bind(this)

        processLine: (line) ->
            if matches = /([^:]+):([0-9]+):([0-9]+):((?:Warning: )?)(.*)/.exec(line)
                [_, fileName, line, col, warning, content] = matches
                type = if warning.length then 'warning' else 'error'
                pos = [parseInt(line, 10) - 1, parseInt(col, 10) - 1]

                content = content.split('\0').filter((l)-> 0 != l.length)
                @currentRequest.onMessage {type, fileName, pos, content}
            else
                console.warn "wut:", line

        exit: ->
            @bp = null
            @queuedRequest = null
            return

            if @queuedRequest?
                r = @queuedRequest
                @currentRequest = null
                @run(r)
