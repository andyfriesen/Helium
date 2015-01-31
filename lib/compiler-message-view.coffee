{View} = require 'atom-space-pen-views'

{findEditor} = require './util'

module.exports =
class CompilerMessageView extends View
    initialize: ({ @line
                 , @column
                 , @fileName # optional
                 , @displayFileName # optional
                 , @message
                 , @preview
                 , @className
                 }) ->
        t = "line #{@line}, column #{@column}"
        if @fileName?
            t += ' of ' + (@displayFileName ? @fileName)
        @$position.text(t)
        @$contents.text(@message)
        @$preview.text(@preview)

        if @className?
            @addClass(@className)

    @content: ->
        @div class: 'line-message', =>
            @div class: 'text-subtle inline-block', outlet: '$position', click: 'onClick', style: 'cursor:pointer'
            @div class: 'message inline-block',     outlet: '$contents', click: 'onClick', style: 'cursor:pointer'
            @pre class: 'preview',                  outlet: '$preview',  click: 'onClick', style: 'cursor:pointer'

    onClick: () ->
        findEditor @fileName, (pane, index, item) =>
            pane.activate()
            pane.activateItemAtIndex(index)
            item.cursors[0].setBufferPosition([@line - 1, @column - 1])
