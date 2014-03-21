parse = require '../lib/parse'

describe 'parse', ->
    it 'says that imports can go at the beginning of an empty Haskell source file', ->
        pos = parse.getPositionOfFirstImport ''
        expect(pos).toEqual([0, 0])

    it 'puts imports after compiler directives', ->
        pos = parse.getPositionOfFirstImport '{-#LANGUAGE OverloadedStrings #-}\n'
        expect(pos).toEqual([1, 0])

    it 'skips nested comments too', ->
        pos = parse.getPositionOfFirstImport '{- haskell comments are not lame like C comments {- you can nest}}-} them -}\n'
        expect(pos).toEqual([1, 0])

    fit 'skips the where clause', ->
        pos = parse.getPositionOfFirstImport '{#- LANGUAGE OverloadedStrings #-}\nmodule Main where\n\nfoo = 99\n'
        expect(pos).toEqual([2, 0])
