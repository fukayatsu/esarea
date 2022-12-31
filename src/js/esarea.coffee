global.jQuery = $ = require('jquery')
require('jquery.selection/src/jquery.selection.js')

return if location.host.match(/qiita\.com|esa\.io|docbase\.io|pplog\.net|lvh\.me|slack\.com|mimemo\.io|kibe\.la|hackmd\.io/)

textareaList = $('textarea:not([data-esarea-disabled="true"])')
return if textareaList.length == 0

suggesting = null

textareaList.each ->
  $(this).keyup (e) ->
    if location.host.match /github\.com/
      suggesting = !!$('ul.suggestions:visible').length
    else if location.host.match /idobata\.io/
      suggesting = !!$('.atwho-view:visible').length
    return

  $(this).keydown (e) ->
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
  $(e.target).selection('setPos', {start: currentLine.start, end: currentLine.end}) if currentLine
  if e.shiftKey
    if currentLine && currentLine.text.charAt(0) == '|'
      # prev cell in table
      newPos = text.lastIndexOf('|', pos.start - 1)
      newPos -= 1 if newPos > 1
      $(e.target).selection('setPos', {start: newPos, end: newPos})
    else
      # re indent
      reindentedText  = $(e.target).selection().replace(/^ {1,4}/gm, '')
      reindentedCount = $(e.target).selection().length - reindentedText.length
      replaceText e.target, reindentedText
      if currentLine
        $(e.target).selection('setPos', {start: pos.start - reindentedCount, end: pos.start - reindentedCount})
      else
        $(e.target).selection('setPos', {start: pos.start, end: pos.start + reindentedText.length})

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
      indentedText = '    ' + $(e.target).selection().split("\n").join("\n    ")
      replaceText e.target, indentedText
      if currentLine
        $(e.target).selection('setPos', {start: pos.start + 4, end: pos.start + 4})
      else
        $(e.target).selection('setPos', {start: pos.start, end: pos.start + indentedText.length})
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
    replaceText e.target, "\n" + listMark
    caretTo = currentLine.caret + listMark.length + 1
    $(e.target).selection('setPos', {start: caretTo, end: caretTo})
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
      replaceText e.target, "\n" + row.join(' --- ') + "\n" + row.join('  ')
      $(e.target).selection('setPos', {start: currentLine.caret + 6 * row.length - 1, end: currentLine.caret + 6 * row.length - 1})
    else
      replaceText e.target, "\n" + row.join('  ')
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
    replaceText e.target, replaceTo
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

# @see https://mimemo.io/m/mqLXOlJe7ozQ19r
replaceText = (target, str) ->
  pos = $(target).selection('getPos')
  fromIdx = pos.start
  toIdx   = pos.end
  inserted = false

  if str
    expectedLen = target.value.length - Math.abs(toIdx - fromIdx) + str.length
    target.focus()
    target.selectionStart = fromIdx
    target.selectionEnd = toIdx
    try
      inserted = document.execCommand('insertText', false, str)
    catch e
      inserted = false
    if inserted and (target.value.length != expectedLen or target.value.substr(fromIdx, str.length) != str)
      #firefoxでなぜかうまくいってないくせにinsertedがtrueになるので失敗を検知してfalseに…
      inserted = false
  if !inserted
    try
      document.execCommand 'ms-beginUndoUnit'
    catch e
    value = target.value
    target.value = '' + value.substring(0, fromIdx) + str + value.substring(toIdx)
    try
      document.execCommand 'ms-endUndoUnit'
    catch e
  $(target).trigger('blur').trigger('focus')
  return
