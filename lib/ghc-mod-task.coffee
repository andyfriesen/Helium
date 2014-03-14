{BufferedProcess} = require 'atom'

ghc_bin = '/usr/bin/ghc'

module.exports =
    class GhcModTask
        constructor: ({bp})->
            @BufferedProcess = bp ? BufferedProcess
            @onMessage = null
            @queuedRequest = null
            @bp = null
            @buffer = null

        run: ({onMessage, fileName}) ->
            if @bp?
                @queuedRequest = {onMessage, fileName}
                return

            @currentRequest = {onMessage, fileName}

            bp_args =
                command: ghc_bin
                args: ['-fno-code', '-Wall', fileName]
                stdout: (line) => @stdout(line)
                stderr: (line) => @stdout(line)
                exit: => @exit()

            console.log "Running", bp_args

            @bp = new @BufferedProcess bp_args

            @buffer = []

        checkBuffer: ->
            if 0 == @buffer.length
                return

            console.group "GHC"
            @buffer.map (l) ->
                console.log [l]

            if /^\[[0-9]+ of [0-9]+\] Compiling.*/.test(@buffer[0])
                # Nothing.  Skip this block.
            else if matches = /([^:]+):([0-9]+):([0-9]+):( Warning:)?/.exec(@buffer[0])
                [_, fileName, line, column, warning] = matches
                @currentRequest.onMessage
                    type: if warning? then 'warning' else 'error'
                    fileName: fileName
                    pos: [parseInt(line, 10) - 1, parseInt(column, 10) - 1]
                    content: @buffer.slice(1).map (s) -> s.substr(4)

            @buffer.splice(0)

            console.groupEnd()

        stdout: (line) ->
            len = line.length
            if line[len - 1] == '\n'
                line = line.substr(0, len - 1)

            line.split('\n').map (l) =>
                if l.length > 0
                    @buffer.push(l)
                else
                    @checkBuffer()

        exit: ->
            @checkBuffer()
            @bp = null
            @queuedRequest = null
            return

            if @queuedRequest?
                r = @queuedRequest
                @currentRequest = null
                @run(r)
