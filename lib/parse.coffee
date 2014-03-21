
# Minimally intelligent Haskell parsing

# FIXME: This cannot possibly be the easiest or most efficient way to do this.

isWhite = (ch) -> ch == ' ' or ch == '\t' or ch == '\n' or ch == '\r'

class Parser
    constructor: (@pos, @sourceCode) ->
        @line = 0
        @col = 0

    eof: ->
        @pos >= @sourceCode.length

    next: (i=1) ->
        while i
            return if @eof()

            i -= 1

            if @sourceCode.charAt(@pos) == '\n'
                @line += 1
                @col = 0
            else
                @col += 1

            @pos += 1

    skipWhitespace: () ->
        console.log 'skipWhite', [@sourceCode.charAt(@pos)], @line, @col
        while !@eof() && isWhite(@sourceCode.charAt(@pos))
            @next()
            console.log 'skipWhite', [@sourceCode.charAt(@pos)], @line, @col
        console.log 'endskipWhite', [@sourceCode.charAt(@pos)], @line, @col

    skipComments: () ->
        return if @eof()

        if @sourceCode.substr(@pos, 2) == '--'
            pos = sourceCode.indexOf('\n', @pos)
            @pos = if pos == -1 then @sourceCode.length else pos + 1
            return true
        else if @sourceCode.substr(@pos, 2) == '{-'
            nestingLevel = 1
            @next(2)
            while nestingLevel > 0
                s = @sourceCode.substr(@pos, 2)

                if s == '{-'
                    nestingLevel += 1
                    @next(2)
                else if s == '-}'
                    nestingLevel -= 1
                    @next(2)
                else
                    @next()

            return true
        else
            return false

    match: (s) ->
        console.log 'match', s, @sourceCode.substr(@pos, s.length)
        if s == @sourceCode.substr(@pos, s.length)
            @pos += s.length
            return true
        else
            return false

    matchWord: (s) ->
        startPos = @pos
        while /[a-zA-Z0-9\.]/.match(@sourceCode.substr(@pos, 1))
            @next()
        return @sourceCode.substr(startPos, @pos)

    nextToken: ->
        @skipComments()

    skipPastModule: ->
        @skipWhitespace()
        r = @skipComments()
        @skipWhitespace()

        if @match('module ')
            name = @matchWord
            if @match(' where')
                @skipWhitespace()
                return

module.exports =

    # Yields the beginning of a line where an import statement can be inserted.
    # Need to skip comments and the module X (...) where declaration.
    # If there is no module statement at the beginning, then it's the beginning of the file.
    getPositionOfFirstImport: (sourceCode) ->
        p = new Parser(0, sourceCode)
        p.skipPastModule()
        return [p.line, p.col]
