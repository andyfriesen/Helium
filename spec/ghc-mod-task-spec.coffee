GhcModTask = require '../lib/ghc-mod-task'

class FakeBufferedProcess
    @allInstances: []

    constructor: ({stdout, exit}) ->
        @stdout = stdout
        @exit = exit
        FakeBufferedProcess.allInstances.push(this)

class FakeFile

class FakeTemp
    @openSync: ({dir, suffix}) ->
        fakefd = {}

        return {fd: fakefd, path: 'goobl'}

class FakeFs
    @writeSync: () ->
    @closeSync: () ->
    @unlinkSync: () ->

describe "GhcModTask", ->
    messages = []

    onMessage = (message) ->
        messages.push(message)

    afterEach ->
        messages.splice(0)
        FakeBufferedProcess.allInstances.splice(0)

    task = new GhcModTask
        bp: FakeBufferedProcess
        fsmodule: FakeFs
        tempmodule: FakeTemp

    describe "check", ->
        process = null
        beforeEach ->
            task.check
                onMessage: onMessage
                fileName: 'TinyTree.hs'
                sourceCode: 'blah'

            [process] = FakeBufferedProcess.allInstances

        it "groups terminal output into messages and reports warnings", ->

            [ "TinyTree.hs:9:28:Warning: Defaulting the following constraint(s) to type `Integer'\0  (Num a0) arising from the literal `1' at TinyTree.hs:9:28\0  (Show a0) arising from a use of `show' at TinyTree.hs:12:16-19\0In the first argument of `Leaf', namely `1'\0In the first argument of `Branch', namely `(Leaf 1)'\0In the expression: Branch (Leaf 1) (Branch (Leaf 2) (Leaf 3))\0"
            ].map process.stdout

            process.exit()

            expect(messages.length).toBe 1
            expect(messages[0].fileName).toBe 'TinyTree.hs'
            expect(messages[0].type).toBe 'warning'
            expect(messages[0].pos).toEqual [9, 28]
            expect(messages[0].content).toEqual(
                [ "Defaulting the following constraint(s) to type `Integer'"
                , "  (Num a0) arising from the literal `1' at TinyTree.hs:9:28"
                , "  (Show a0) arising from a use of `show' at TinyTree.hs:12:16-19"
                , "In the first argument of `Leaf', namely `1'"
                , "In the first argument of `Branch', namely `(Leaf 1)'"
                , "In the expression: Branch (Leaf 1) (Branch (Leaf 2) (Leaf 3))"
                ]
            )

        it 'reports errors', ->
            [ "TinyTree.hs:12:5:Couldn't match expected type `()' with actual type `IO ()'\0In a stmt of a 'do' block: putStrLn $ show foo\0In the expression:\0  do { let foo = Branch (Leaf 1) (Branch (Leaf 2) (Leaf 3))\0           bar = foo 22;\0       putStrLn $ show foo }\0In an equation for `main':\0    main\0      = do { let foo = Branch (Leaf 1) (Branch (Leaf 2) (Leaf 3))\0                 bar = foo 22;\0             putStrLn $ show foo }\0"
            ].map process.stdout

            process.exit()

            expect(messages.length).toBe 1
            expect(messages[0].type).toBe 'error'
            expect(messages[0].pos).toEqual [12, 5]

            expect(messages[0].content).toEqual(
                [ "Couldn't match expected type `()' with actual type `IO ()'"
                , "In a stmt of a 'do' block: putStrLn $ show foo"
                , "In the expression:"
                , "  do { let foo = Branch (Leaf 1) (Branch (Leaf 2) (Leaf 3))"
                , "           bar = foo 22;"
                , "       putStrLn $ show foo }"
                , "In an equation for `main':"
                , "    main"
                , "      = do { let foo = Branch (Leaf 1) (Branch (Leaf 2) (Leaf 3))"
                , "                 bar = foo 22;"
                , "             putStrLn $ show foo }"
                ]
            )

    describe "getType", ->
        process = null
        beforeEach ->
            task.getType
                onMessage: onMessage
                fileName: 'TinyTree.hs'
                sourceCode: 'fakey'
                pos: [9, 9]

            [process] = FakeBufferedProcess.allInstances

        it 'reports types', ->
            [ '9 23 9 27 "Integer -> Tree Integer"'
            , '9 23 9 29 "Tree Integer"'
            , '9 22 9 30 "Tree Integer"'
            , '9 15 9 30 "Tree Integer -> Tree Integer"'
            , '9 15 9 57 "Tree Integer"'
            , '9 9 9 57 "Tree Integer"'
            , '8 8 12 24 "IO ()"'
            , '8 1 12 24 "IO ()"'
            ].map process.stdout

            process.exit()

            expect(messages.length).toBe 8
            expect(messages[0]).toEqual
                type: 'Integer -> Tree Integer'
                startPos: [9, 23]
                endPos: [9, 27]
