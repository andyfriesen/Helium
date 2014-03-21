Parser = require '../lib/parse'

parseWith = (src) ->
    new Parser(src)

describe 'nextToken', ->
    it 'fetches the first token', ->
        p = parseWith '   module   '
        expect(p.nextToken()).toEqual 'module'

    it 'fetches a second token', ->
        p = parseWith '  module\n module   '
        expect(p.nextToken()).toEqual 'module'
        expect(p.nextToken()).toEqual 'module'

    it 'skips a line comment', ->
        p = parseWith ' -- comment goes here\nmodule'
        expect(p.nextToken()).toEqual 'module'

    it 'skips a block comment', ->
        p = parseWith ' {- comment goes here -} \tmodule'
        expect(p.nextToken()).toEqual 'module'

    it 'skips a nested block comment', ->
        p = parseWith ' {- block { comments {- are -} the best -} module'
        expect(p.nextToken()).toEqual 'module'

    it 'skips multiple comments', ->
        p = parseWith '-- first line\n--second line\r\nmodule'
        expect(p.nextToken()).toEqual 'module'

describe 'moduleDecl', ->
    it 'parses a basic module declaration', ->
        p = parseWith 'module Main where\n'
        expect(p.moduleDecl()).toEqual {moduleName: 'Main', exports: []}

    it 'fails', ->
        p = parseWith ' -- la la la\nfoo = 22'
        expect(p.moduleDecl()).toEqual null
        expect(p.pos).toBe 0

    it 'parses a basic export list', ->
        p = parseWith 'module Foo (x, y, z) where'
        expect(p.moduleDecl()).toEqual { moduleName: 'Foo', exports: [{name:'x'}, {name:'y'}, {name:'z'}]}

    it 'parses an export list that names constructors', ->
        p = parseWith 'module Foo (Point (x, y)) where'
        expect(p.moduleDecl()).toEqual { moduleName: 'Foo', exports: [{name:'Point', props: ['x', 'y']}]}
