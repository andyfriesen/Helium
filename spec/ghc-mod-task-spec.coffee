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

    task.run
        onMessage: onMessage
        fileName: 'TinyTree.hs'

    [process] = FakeBufferedProcess.allInstances

    it "groups terminal output into messages and reports warnings", ->
        [ "[1 of 1] Compiling Main             ( TinyTree.hs, nothing )\n"
        , "\n"
        , "TinyTree.hs:7:1: Warning:\n"
        , "    Top-level binding with no type signature: main :: IO ()\n"
        , "\n"
        , "TinyTree.hs:8:28: Warning:\n"
        , "    Defaulting the following constraint(s) to type `Integer'\n"
        , "      (Num a0) arising from the literal `1' at TinyTree.hs:8:28\n"
        , "      (Show a0) arising from a use of `show' at TinyTree.hs:10:16-19\n"
        , "    In the first argument of `Leaf', namely `1'\n"
        , "    In the first argument of `Branch', namely `(Leaf 1)'\n"
        , "    In the expression: Branch (Leaf 1) (Branch (Leaf 2) (Leaf 3))\n"
        ].map process.stdout

        process.exit()

        expect(messages.length).toBe 2
        expect(messages[0].fileName).toBe 'TinyTree.hs'
        expect(messages[0].type).toBe 'warning'
        expect(messages[0].pos).toEqual [6, 0]
        expect(messages[0].content).toEqual ['Top-level binding with no type signature: main :: IO ()']

    it 'reports errors', ->
        [ "[1 of 1] Compiling Main             ( TinyTree.hs, nothing )\n"
        , "\n"
        , "TinyTree.hs:8:1:\n"
        , "    Couldn't match expected type `IO t0' with actual type `()'\n"
        , "    In the expression: main\n"
        , "    When checking the type of the function `main'\n"
        , "\n"
        , "TinyTree.hs:11:5:\n"
        , "    Couldn't match expected type `()' with actual type `IO ()'\n"
        , "    In a stmt of a 'do' block: putStrLn $ show foo\n"
        , "    In the expression:\n"
        , "      do { let foo = Branch (Leaf 1) (Branch (Leaf 2) (Leaf 3));\n"
        , "           putStrLn $ show foo }\n"
        , "    In an equation for `main':\n"
        , "        main\n"
        , "          = do { let foo = ...;\n"
        , "                 putStrLn $ show foo }\n"
        ].map process.stdout

        process.exit()

        expect(messages.length).toBe 2
        expect(messages[0].type).toBe 'error'
        expect(messages[0].pos).toEqual [7, 0]
        expect(messages[0].content[0]).toEqual "Couldn't match expected type `IO t0' with actual type `()'"

        expect(messages[1].content).toEqual(
            [ "Couldn't match expected type `()' with actual type `IO ()'"
            , "In a stmt of a 'do' block: putStrLn $ show foo"
            , "In the expression:"
            , "  do { let foo = Branch (Leaf 1) (Branch (Leaf 2) (Leaf 3));"
            , "       putStrLn $ show foo }"
            , "In an equation for `main':"
            , "    main"
            , "      = do { let foo = ...;"
            , "             putStrLn $ show foo }"
            ]
        )
