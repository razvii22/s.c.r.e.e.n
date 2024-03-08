local strings = require("cc.strings")
local ratu = {}

---Takes in a string and formats it using string.format() and also colors text based on color codes as described below, the values corespond to blit colors.
---@param str string string containing control codes, &[0-9a-f] for foreground color, and &&[0-9a-f] for background.
---@param nl boolean? whether to insert a newline at the end
---|true
---|false
---@param ... unknown? passthrough for string.format, any format variables in the string can be referenced here.
ratu.printColored = function(str, nl, ...)
  local str = tostring(str)
  local indices = {}
  local fstr = str:format(...)

  --#region control code findery:tm:
  local startIndex = 1
  while true do
    local start, finish, codeType
    local doubleCodeStart, doubleCodeFinish = fstr:find("&&[0-9a-f]", startIndex)
    local singleCodeStart, singleCodeFinish = fstr:find("&[0-9a-f]", startIndex)

    if doubleCodeStart and (not singleCodeStart or doubleCodeStart < singleCodeStart) then
      start, finish, codeType = doubleCodeStart, doubleCodeFinish, "bg"
    elseif singleCodeStart then
      start, finish, codeType = singleCodeStart, singleCodeFinish, "fg"
    else
      break
    end
    finish = finish or 0
    -- Add new code
    indices[#indices + 1] = { index = start, code = { codeType, fstr:sub(finish, finish) } }

    -- Remove the current color code from the string
    fstr = fstr:sub(1, start - 1) .. fstr:sub(finish + 1)
    startIndex = start
  end
  --#endregion

  --#region Splitting the string by control codes :3
  local stringTable = {}
  if #indices > 0 then
    if indices[1].index > 1 then
      local index = #stringTable + 1
      stringTable[index] = {}
      stringTable[index].str = fstr:sub(1, indices[1].index - 1)
    end
    for key, value in pairs(indices) do
      local stringEnd = indices[key + 1] and indices[key + 1].index - 1 or #fstr
      local index = #stringTable + 1
      stringTable[index] = {}
      stringTable[index].str = fstr:sub(value.index, stringEnd)
      stringTable[index].code = value.code
    end
  else
    stringTable[1] = { ["str"] = fstr }
  end
  --#endregion
  for key, value in pairs(stringTable) do
    if value.code then
      if value.code[1] == "bg" then
        term.setBackgroundColor(2 ^ tonumber("0x" .. value.code[2]))
      elseif value.code[1] == "fg" then
        term.setTextColor(2 ^ tonumber("0x" .. value.code[2]))
      end
    end
    term.write(value.str)
  end
  if nl then
    print()
  end
end

ratu.countCodeChars = function(str)
  local input = str
  local count = 0
  for index in input:gmatch("&&[0-9a-f]") do
    count = count + #index
  end
  input = input:gsub("&&[0-9a-f]","")
  for index in input:gmatch("&[0-9a-f]") do
    count = count + #index
  end
  return count
end

ratu.printCentered = function(str, x, y, nl, ...)
	local curx, cury = term.getCursorPos()
	local str = tostring(str)
  local strlen = #str - ratu.countCodeChars(str)

	term.setCursorPos((x or curx)-math.floor(strlen/2)+1, y or cury)
	ratu.printColored(str, nl, ...)
end

---Prints a given string using printColored with a delay between each word, and optionally with a ticking sound between them.
---@param text string string containing control codes, &[0-9a-f] for foreground color, and &&[0-9a-f] for background.
---@param delay number? the delay between each word printed(sleep only goes as slow as 0.025s, which is the default if not provided)
---@param spk ccTweaked.peripherals.Speaker Speaker? the speaker object to play the ticking sound through, nil to not have it play, this uses a sound from the Create mod, you can replace it.
---@param nl boolean? whether to newline at the end of the last segment.
---@param ... unknown? passthrough for string.format, any format variables in the string can be referenced here.
ratu.wordwisePrint = function(text, delay, spk, nl, ...)
  local text = tostring(text)
  local words = {}
  for value in text:gmatch("([^" .. " " .. "]+)") do
    words[#words + 1] = value
  end
  for key, value in pairs(words) do
    local space = (key == #words) and "" or " "
    ratu.printColored(value .. space, false, ...)
    --plays a typing sound if a speaker is provided.
    if spk then
      spk.playSound("create:scroll_value", 0.3, 3)
    end
    sleep(delay or 0)
  end
  if nl then
    print()
  end
end

---Prints a given string using printColored with a delay between each word, and optionally with a ticking sound between them.
---@param text string string containing control codes, &[0-9a-f] for foreground color, and &&[0-9a-f] for background.
---@param delay number? the delay between each segment printed(sleep only goes as slow as 0.025s, which is the default if not provided)
---@param length number? the length of the printed segments, defaults to 5
---@param spk ccTweaked.peripherals.Speaker? the speaker object to play the ticking sound through, nil to not have it play, this uses a sound from the Create mod, you can replace it.
---@param nl boolean? whether to newline at the end of the last segment.
---@param ... unknown? passthrough for string.format, any format variables in the string can be referenced here.
ratu.lenghtwisePrint = function(text, delay, length, spk, nl, ...)
  local text = tostring(text)
  local length = length or 5
  local wrapped = strings.wrap(text, term.getSize())

  for key, lines in pairs(wrapped) do
    local segments = {}
    local startSegment = 1
    while true do
      local segment = lines:sub(startSegment, startSegment + length - 1)
      if segment:sub(#segment, #segment) == "&" then
        segment = lines:sub(startSegment, startSegment + length + 1)
      end
      segments[#segments + 1] = segment
      if (startSegment + length) > #lines then
        break
      end
      startSegment = startSegment + #segment
    end
    for _, strs in pairs(segments) do
      ratu.printColored(strs, false, ...)
      if spk then
        spk.playSound("create:scroll_value", 0.3, 3)
      end
      sleep(delay or 0)
    end
    if key ~= #wrapped then
      print()
    end
  end
  if nl then
    print()
  end
end

return ratu
