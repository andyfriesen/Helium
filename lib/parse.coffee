
# Minimally intelligent Haskell parsing

# FIXME: This cannot possibly be the easiest or most efficient way to do this.

isWhite = (ch) -> ch == ' ' or ch == '\t' or ch == '\n' or ch == '\r'

isDigit = (ch) ->
    c = ch.charCodeAt(0)
    return 48 <= c <= 57

# FIXME: Unicode.

isAlpha = (ch) ->
    c = ch.charCodeAt(0)
    return (c == 95) || (65 <= c <= 90) || (97 <= c <= 122)

isAlphaNum = (ch) -> isAlpha(ch) || isDigit(ch)

isIdentifier = (s) -> /[a-z][a-zA-Z0-9]*/.exec(s)

isModuleName = (s) -> /[A-Z][a-zA-Z0-9]*/.exec(s)

OPERATORS = [
    '(',
    ')',
    '..',
    ','
]

isOperator = (s)-> -1 != OPERATORS.indexOf(s)

module.exports =
class Parser
    constructor: (@sourceCode) ->
        @pos = @line = @col = 0

    eof: ->
        @pos >= @sourceCode.length

    peek: (count=1) ->
        return @sourceCode.substr(@pos, count)

    next: (i=1) ->
        while i > 0
            return if @eof()

            i -= 1

            if @sourceCode.charAt(@pos) == '\n'
                @line += 1
                @col = 0
            else
                @col += 1

            @pos += 1

    eatWhitespace: ->
        while true
            if isWhite(@peek())
                @next()
                continue
            else if '--' == @peek(2)
                @next(2)
                while !@eof() and '\n' != @peek()
                    @next()
                continue
            else if '{-' == @peek(2)
                @next(2)
                nestLevel = 1
                while !@eof() and nestLevel > 0
                    s = @peek(2)
                    if s == '{-'
                        nestLevel += 1
                        @next(2)
                    else if s == '-}'
                        nestLevel -= 1
                        @next(2)
                    else
                        @next()
                continue
            else
                return

    nextToken: ->
        @eatWhitespace()
        if @eof()
            return null

        if isAlpha(@peek())
            start = @pos
            while true
                @next()
                if not isAlpha(@peek())
                    break

            return @sourceCode.substring(start, @pos)

        for op in OPERATORS
            if op == @peek(op.length)
                @next(op.length)
                return op

    moduleName: ->
        startPos = @pos
        fail = =>
            @pos = startPos
            return null

        segment = @nextToken()
        if not isModuleName(segment)
            return fail()

        segments = [segment]
        p = @pos
        while true
            if @nextToken() != '.'
                @pos = p
                return segments.join('.')

            segment = @nextToken()
            if not isModuleName(segment)
                return fail

            segments.push(segment)

    parsePropList: ->
        startPos = @pos
        fail = =>
            @pos = startPos
            return null

        t = @nextToken()
        if t != '('
            return fail()

        p = @pos
        t = @nextToken()
        if t == ')'
            return []
        @pos = p

        props = []
        while true
            t = @nextToken()
            if isIdentifier(t) or t == '..'
                props.push(t)
                p = @pos
                t = @nextToken()
                if t == ')'
                    break
                else if t == ','
                    continue
                else
                    return fail()

        return props


    moduleDecl: ->
        startPos = @pos
        fail = =>
            @pos = startPos
            return null

        if @nextToken() != 'module'
            return fail()

        name = @moduleName()
        if name == null
            return fail()

        t = @nextToken()
        if t == 'where'
            return {moduleName: name, exports: []}

        else if t == '('
            exportList = []
            p = @pos
            t = @nextToken()
            if t == ')'
                t = @nextToken()
                if t != 'where'
                    return fail()

                return { moduleName: name, exports: exportList }
            else
                @pos = p

            while true
                tok = @nextToken()
                if isIdentifier(tok)
                    p = @pos
                    t = @nextToken()
                    props = []

                    if t == '('
                        @pos = p
                        props = @parsePropList()
                        if null == props
                            return fail()
                        t = @nextToken()

                    if props.length
                        exportList.push({name: tok, props: props})
                    else
                        exportList.push({name: tok})

                    if t == ','
                        continue
                    else if t == ')'
                        t = @nextToken()
                        if t != 'where'
                            return fail()
                        return { moduleName: name, exports: exportList }
                    else
                        return fail()
                else
                    return fail()

        else
            return fail()
