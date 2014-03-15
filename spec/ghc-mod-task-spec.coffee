GhcModTask = require '../lib/ghc-mod-task'

class FakeBufferedProcess
    @allInstances: []

    constructor: ({stdout, exit}) ->
        @stdout = stdout
        @exit = exit
        FakeBufferedProcess.allInstances.push(this)

describe "GhcModTask", ->
    messages = []

    onMessage = (message) ->
        messages.push(message)

    afterEach ->
        messages.splice(0)
        FakeBufferedProcess.allInstances.splice(0)

    task = new GhcModTask
        bp: FakeBufferedProcess

    task.check
        onMessage: onMessage
        fileName: 'TinyTree.hs'

    [process] = FakeBufferedProcess.allInstances

    it "groups terminal output into messages and reports warnings", ->

        [ "TinyTree.hs:9:28:Warning: Defaulting the following constraint(s) to type `Integer'\0  (Num a0) arising from the literal `1' at TinyTree.hs:9:28\0  (Show a0) arising from a use of `show' at TinyTree.hs:12:16-19\0In the first argument of `Leaf', namely `1'\0In the first argument of `Branch', namely `(Leaf 1)'\0In the expression: Branch (Leaf 1) (Branch (Leaf 2) (Leaf 3))\0"
        ].map process.stdout

        process.exit()

        expect(messages.length).toBe 1
        expect(messages[0].fileName).toBe 'TinyTree.hs'
        expect(messages[0].type).toBe 'warning'
        expect(messages[0].pos).toEqual [8, 27]
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
        expect(messages[0].pos).toEqual [11, 4]

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
