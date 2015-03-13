$(document).on 'keydown', 'textarea', (e) ->
  switch (e.which || e.keyCode)
    when 9 # Tab
      e.preventDefault()
      pos = $(e.target).selection('getPos')
      isMultiLine = pos.start != pos.end
      text = $(e.target).val()
      lines = text.split("\n")
      start = 0
      lastLine    = null
      startByLine = null
      endByLine   = null
      for line in lines
        end = start + line.length + 1
        if (start <= pos.start && pos.start < end) || (start <= pos.end && pos.end < end)
          lastLine    = line
          startByLine = start if startByLine == null
          endByLine   = end
        start = end
      $(e.target).selection('setPos', {start: startByLine, end: (endByLine - 1)})
      if e.shiftKey
        if !isMultiLine && lastLine.charAt(0) == '|'
          newPos = text.lastIndexOf('|', pos.start - 1)
          $(e.target).selection('setPos', {start: newPos - 1, end: newPos - 1}) if newPos > 0
        else
          # re indent
          reindentedText  = $(e.target).selection().replace(/^ {1,4}/gm, '')
          reindentedCount = $(e.target).selection().length - reindentedText.length
          $(e.target).selection('replace', {text: reindentedText, mode: 'before'});
          unless isMultiLine
            $(e.target).selection('setPos', {start: pos.start - reindentedCount, end: pos.start - reindentedCount})
      else
        # indent
        if !isMultiLine && lastLine.charAt(0) == '|'
          newPos = text.indexOf('|', pos.start + 1)
          if (newPos < 0) || (newPos == text.lastIndexOf('|', endByLine - 1))
            $(e.target).selection('setPos', {start: endByLine - 1, end: endByLine - 1})
          else
            $(e.target).selection('setPos', {start: newPos + 2, end: newPos + 2 })
        else
          $(e.target).selection('replace', {
            text: '    ' + $(e.target).selection().split("\n").join("\n    "),
            mode: 'before'
          });
          $(e.target).selection('setPos', {start: pos.start + 4, end: pos.start + 4}) unless isMultiLine
      $(e.target).trigger('input')
    when 13 # Enter
      return if e.metaKey || e.ctrlKey || e.shiftKey # for cmd + enter
      pos = $(e.target).selection('getPos')
      isMultiLine = pos.start != pos.end
      return if isMultiLine
      lines = $(e.target).val().split("\n")
      start = 0
      lastLine = null
      startByLine = null
      endByLine   = null
      nextLineNum = 0
      for line in lines
        end = start + line.length + 1
        if (start <= pos.start)
          lastLine = line
          startByLine = start
          endByLine   = end
          nextLineNum += 1
        start = end
      return if pos.start == startByLine
      if match = lastLine.match(/^(\s*(?:-|\+|\*) (?:\[(?:x| )\] )?)\s*\S/)
        # smart indent with list
        if lastLine.match(/^(\s*(?:-|\+|\*) (?:\[(?:x| )\] ))\s*$/)
          # empty task list
          $(e.target).selection('setPos', {start: startByLine, end: (endByLine - 1)})
          return
        e.preventDefault()
        $(e.target).selection('insert', {text: "\n" + match[1], mode: 'before'});
      else if lastLine.match(/^(\s*(?:-|\+|\*) )/)
        # remove list
        $(e.target).selection('setPos', {start: startByLine, end: (endByLine - 1)})
      else if lastLine.match(/^.*\|\s*$/)
        # new row for table
        if lastLine.match(/^[\|\s]+$/)
          $(e.target).selection('setPos', {start: startByLine, end: (endByLine - 1)})
          return
        return unless pos.start == (endByLine - 1) # only on the end of line
        e.preventDefault()
        row = []
        row.push "|" for match in lastLine.match(/\|/g)
        if nextLineNum == 1 || (!lastLine.match(/---/) && lines[nextLineNum - 2].match(/^\S*$/))
          $(e.target).selection('insert', {text: "\n" + row.join(' --- ') + "\n" + row.join('  '), mode: 'before'});
          $(e.target).selection('setPos', {start: pos.start + 6 * row.length - 1, end: pos.start + 6 * row.length - 1})
        else
          $(e.target).selection('insert', {text: "\n" + row.join('  '), mode: 'before'});
          $(e.target).selection('setPos', {start: pos.start + 3, end: pos.start + 3 })
      $(e.target).trigger('input')
    when 32 # space
      return unless e.shiftKey && e.altKey
      text = $(e.target).val()
      pos  = $(e.target).selection('getPos')
      return unless pos.start == pos.end
      startPos = text.lastIndexOf("\n", pos.start - 1) + 1
      endPos   = text.indexOf("\n", pos.start)
      endPos   = text.length if endPos == -1
      currentLine = text.slice(startPos, endPos)
      if match = currentLine.match(/^(\s*)(-|\+|\*) (?:\[(x| )\] )(.*)/)
        e.preventDefault()
        checkMark = if match[3] == ' ' then 'x' else ' '
        replaceTo = "#{match[1]}#{match[2]} [#{checkMark}] #{match[4]}"
        $(e.target).selection('setPos', {start: startPos, end: endPos})
        $(e.target).selection('replace', {text: replaceTo, mode: 'keep'})
        $(e.target).selection('setPos', {start: pos.start, end: pos.end})
        $(e.target).trigger('input')
