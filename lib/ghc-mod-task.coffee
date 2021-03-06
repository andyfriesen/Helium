{BufferedProcess} = require 'atom'
path              = require 'path'
fs                = require 'fs'
temp              = require 'temp'
Parser            = require './parse'
{isSamePath}      = require './util'


GHC_MOD_BIN = 'ghc-mod'

ghcmod = null

getGhcMod = ->
    if null != ghcmod
        return ghcmod

    paths = process.env.PATH.split(path.delimiter)
    if process.platform == 'darwin'
        paths.unshift(path.join(process.env.HOME, 'Library/Haskell/bin'))

    suffix = ''
    if process.platform == 'win32'
        suffix = '.exe'

    for p in paths
        candidate = path.join(p, 'ghc-mod' + suffix)
        if fs.existsSync(candidate)
            ghcmod = candidate
            return ghcmod

    console.error("Could not find ghc-mod!  Paths searched:", paths)
    throw "Could not find ghc-mod!"

module.exports =
    class GhcModTask
        constructor: ({bp, fsmodule, tempmodule, atomconfig})->
            @BufferedProcess = bp ? BufferedProcess
            @fs = fsmodule ? fs
            @temp = tempmodule ? temp
            @atomconfig = atomconfig ? atom.config
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
                cwd: path.dirname(fileName)
                onMessage: (line) =>
                    if matches = /((\w:\\)?[^:]+):(\d+):(\d+):((?:Warning: )?)(.*)/.exec(line)
                        [_, fn, _driveSpec, line, col, warning, content] = matches
                        if isSamePath(fn, @tempFile)
                            fn = fileName
                        else
                            fn = path.join(path.dirname(fileName), fn)

                        type = if warning.length then 'warning' else 'error'
                        pos = [parseInt(line, 10), parseInt(col, 10)]

                        content = content.split('\0').filter((l)-> 0 != l.length)
                        onMessage {type, fileName: fn, pos, content}
                    else
                        console.warn "check got confusing output from ghc-mod:", [line]

        getType: ({onMessage, fileName, sourceCode, pos}) ->
            p = new Parser(sourceCode)
            decl = p.moduleDecl()
            moduleName = if decl? then decl.moduleName else 'Main'

            @tempFile = @mkTemp(fileName, sourceCode)
            @run
                command: 'type'
                args: [@tempFile, moduleName, pos[0] + 1, pos[1] + 1]
                cwd: path.dirname(fileName)
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
            extension = if /.*\.lhs$/.exec(fileName) then '.lhs' else '.hs'
            info = @temp.openSync({dir:dir, suffix: extension})
            @fs.writeSync(info.fd, contents, 0, contents.length, 0)
            @fs.closeSync(info.fd)
            return info.path

        run: ({onMessage, onComplete, command, args, cwd}) ->
            options = if cwd then { cwd: cwd } else {}
            cmdArgs = args.slice(0)
            cmdArgs.unshift(command)

            extraArgs = @atomconfig.get 'helium.ghc_mod_options'

            if extraArgs?
                cmdArgs = cmdArgs.concat(extraArgs.split ' ')

            if @bp?
                @queuedRequest = {onMessage, command, args}
                return

            @currentRequest = {onMessage, command, args}

            bp_args =
                command: getGhcMod()
                args: cmdArgs
                options: options
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
