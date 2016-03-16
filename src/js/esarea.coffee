return if location.host.match(/qiita\.com|esa\.io|docbase\.io|pplog\.net|lvh\.me|slack\.com|mimemo\.io/)

suggesting = null
$(document).on 'keyup', 'textarea', (e) ->
  if location.host.match /github\.com/
    suggesting = !!$('ul.suggestions:visible').length
  else if location.host.match /idobata\.io/
    suggesting = !!$('.atwho-view:visible').length
  return

$(document).on 'keydown', 'textarea', (e) ->
  return if suggesting

  switch (e.which || e.keyCode)
    when 9
      handleTabKey(e)
    when 13
      handleEnterKey(e)
    when 32
      handleSpaceKey(e)
  return

handleTabKey = (e) ->
  e.preventDefault()
  currentLine = getCurrentLine(e)
  text = $(e.target).val()
  pos  = $(e.target).selection('getPos')
  $(e.target).selection('setPos', {start: currentLine.start, end: (currentLine.end - 1)}) if currentLine
  if e.shiftKey
    if currentLine && currentLine.text.charAt(0) == '|'
      # prev cell in table
      newPos = text.lastIndexOf('|', pos.start - 1)
      $(e.target).selection('setPos', {start: newPos - 1, end: newPos - 1}) if newPos > 0
    else
      # re indent
      reindentedText  = $(e.target).selection().replace(/^ {1,4}/gm, '')
      reindentedCount = $(e.target).selection().length - reindentedText.length
      $(e.target).selection('replace', {text: reindentedText, mode: 'before'});
      $(e.target).selection('setPos', {start: pos.start - reindentedCount, end: pos.start - reindentedCount}) if currentLine
  else
    if currentLine && currentLine.text.charAt(0) == '|'
      # next cell in table
      newPos = text.indexOf('|', pos.start + 1)
      if (newPos < 0) || (newPos == text.lastIndexOf('|', currentLine.end - 1))
        $(e.target).selection('setPos', {start: currentLine.end, end: currentLine.end})
      else
        $(e.target).selection('setPos', {start: newPos + 2, end: newPos + 2 })
    else
      # indent
      $(e.target).selection('replace', {
        text: '    ' + $(e.target).selection().split("\n").join("\n    "),
        mode: 'before'
      });
      $(e.target).selection('setPos', {start: pos.start + 4, end: pos.start + 4}) if currentLine
  $(e.target).trigger('input')

handleEnterKey = (e) ->
  return if e.metaKey || e.ctrlKey || e.shiftKey # for cmd + enter
  return unless currentLine = getCurrentLine(e)
  return if currentLine.start == currentLine.caret
  if match = currentLine.text.match(/^(\s*(?:-|\+|\*|\d+\.) (?:\[(?:x| )\] )?)\s*\S/)
    # smart indent with list
    if currentLine.text.match(/^(\s*(?:-|\+|\*|\d+\.) (?:\[(?:x| )\] ))\s*$/)
      # empty task list
      $(e.target).selection('setPos', {start: currentLine.start, end: (currentLine.end - 1)})
      return
    e.preventDefault()
    listMark = match[1].replace(/\[x\]/, '[ ]')
    if listMarkMatch = listMark.match /^(\s*)(\d+)\./
      indent = listMarkMatch[1]
      num    = parseInt(listMarkMatch[2])
      listMark = listMark.replace(/\s*\d+/, "#{indent}#{num + 1}") unless num == 1
    $(e.target).selection('insert', {text: "\n" + listMark, mode: 'before'});
  else if currentLine.text.match(/^(\s*(?:-|\+|\*|\d+\.) )/)
    # remove list
    $(e.target).selection('setPos', {start: currentLine.start, end: (currentLine.end)})
  else if currentLine.text.match(/^.*\|\s*$/)
    # new row for table
    if currentLine.text.match(/^[\|\s]+$/)
      $(e.target).selection('setPos', {start: currentLine.start, end: (currentLine.end)})
      return
    return unless currentLine.endOfLine
    e.preventDefault()
    row = []
    row.push "|" for match in currentLine.text.match(/\|/g)
    prevLine = getPrevLine(e)
    if !prevLine || (!currentLine.text.match(/---/) && !prevLine.text.match(/\|/g))
      $(e.target).selection('insert', {text: "\n" + row.join(' --- ') + "\n" + row.join('  '), mode: 'before'});
      $(e.target).selection('setPos', {start: currentLine.caret + 6 * row.length - 1, end: currentLine.caret + 6 * row.length - 1})
    else
      $(e.target).selection('insert', {text: "\n" + row.join('  '), mode: 'before'});
      $(e.target).selection('setPos', {start: currentLine.caret + 3, end: currentLine.caret + 3 })
  $(e.target).trigger('input')

handleSpaceKey = (e) ->
  return unless e.shiftKey && e.altKey
  return unless currentLine = getCurrentLine(e)
  if match = currentLine.text.match(/^(\s*)(-|\+|\*|\d+\.) (?:\[(x| )\] )(.*)/)
    e.preventDefault()
    checkMark = if match[3] == ' ' then 'x' else ' '
    replaceTo = "#{match[1]}#{match[2]} [#{checkMark}] #{match[4]}"
    $(e.target).selection('setPos', {start: currentLine.start, end: currentLine.end})
    $(e.target).selection('replace', {text: replaceTo, mode: 'keep'})
    $(e.target).selection('setPos', {start: currentLine.caret, end: currentLine.caret})
    $(e.target).trigger('input')

getCurrentLine = (e) ->
  text = $(e.target).val()
  pos  = $(e.target).selection('getPos')

  return null if !text
  return null unless pos.start == pos.end

  startPos = text.lastIndexOf("\n", pos.start - 1) + 1
  endPos   = text.indexOf("\n", pos.start)
  endPos   = text.length if endPos == -1
  {
    text:  text.slice(startPos, endPos),
    start: startPos,
    end:   endPos,
    caret: pos.start,
    endOfLine: !$.trim(text.slice(pos.start, endPos))
  }

getPrevLine = (e) ->
  currentLine = getCurrentLine(e)
  text = $(e.target).val().slice(0, currentLine.start)

  startPos = text.lastIndexOf("\n", currentLine.start - 2) + 1
  endPos   = currentLine.start
  {
    text:  text.slice(startPos, endPos),
    start: startPos,
    end:   endPos
  }
