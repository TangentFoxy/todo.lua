#!/usr/bin/env luajit

math.randomseed(os.time())

local patterns = {
  date = "%d%d%d%d%-%d%d%-%d%d",
  priority = "%u",
}

local function add_list_printing(list)
  local function leftpad(str, width)
    if not width then width = 4 end
    str = tostring(str)
    return string.rep(" ", width - #str) .. str
  end
  local function pad(str, width)
    if not width then width = 4 end
    str = tostring(str)
    return str .. string.rep(" ", width - #str)
  end

  setmetatable(list, {
    __tostring = function(t)
      local output = {}
      for index, value in pairs(t) do
        table.insert(output, pad(leftpad(index, 4), 8) .. tostring(value))
      end
      table.sort(output)
      return table.concat(output, "\n")
    end,
  })

  return list
end

local function new_list()
  local list = {}
  add_list_printing(list)
  return list
end

local function tokenize(text)
  local tokens = new_list()
  if not type(text) == "string" then
    error("tokenize() only accepts strings.")
  end

  -- TODO grouping characters should group sections of text?
  --  this should be an advanced option,
  --  as the spec forbids it
  --  "" '' `` [] {} ()
  for token in text:gmatch("%S+") do
    table.insert(tokens, token)
  end
  return tokens
end

local function get_tags(object, tag_type)
  if not object then
    error("get_tags() requires an argument.")
  end

  local tag_symbols = {
    tag = "#",
    project = "+",
    context = "@",
    custom = ":",
  }

  local function parse(tokens, tag_type)
    local tags = new_list()
    if not tag_type then
      error("Must be called with a tag type.")
    end

    if tag_type == tag_symbols.custom then
      for _, token in pairs(tokens) do
        local index = token:find(tag_type)
        if index then
          table.insert(tags, token:sub(1, index))
        end
      end
    else
      for _, token in pairs(tokens) do
        if token:find(tag_type) == 1 then
          table.insert(tags, token)
        end
      end
    end

    return tags
  end

  -- BUG this function destroys how I want lists to work
  --  list numbering must be preserved elsewhere, this is very hacky
  local function append(recipient_list, source_list)
    if not (type(recipient_list) == "table" and type(source_list) == "table") then
      error("append() only accepts tables.")
    end

    for _, item in ipairs(source_list) do
      table.insert(recipient_list, item)
    end
    return recipient_list
  end

  local tags
  if type(object) == "table" then
    -- TODO recognize this as an options table
    --  options: items (list of items), tokens, item (single string)
    -- the remainder of this function is the "else"; assumes a single item
    -- TODO write the rest of this
    error("Not implemented.")
  else
    local tokens = tokenize(object)
    if tag_type then
      tags = parse(tokens, tag_type)
    end
    if not tag_type then
      for _, tag in pairs(tag_symbols) do
        tags = append(tags, parse(tokens, tag)) -- I hate this (because it is hacky)
      end
    end
  end

  return tags
end

local function load()
  local items = new_list()
  for line in io.lines("todo.txt") do
    if #line > 0 then
      table.insert(items, line)
    end
  end
  return items
end

local function save(list)
  -- TODO make able to save to different locations or not backup every time
  if not list then
    error("save() requires an argument.")
  end

  backup_file_name = os.date(".todo.txt-%Y.%m.%d-%H.%M.%s-" .. math.random(), os.time())
  os.execute("cp todo.txt " .. backup_file_name)

  local file, err = io.open("todo.txt", "w")
  if err then error(err) end

  local ordered_list = {}
  for index, item, in pairs(list) do
    table.insert(ordered_list, {index = index, item = item})
  end
  table.sort(ordered_list, function(a, b) return a.index < b.index end)

  for _, item in ipairs(ordered_list) do
    file:write(item.item .. "\n")
  end
  file:close()
end

local function parse_item(text)
  local item = {
    complete = false,
    priority = 27,
    completion_date = false,
    creation_date = false,
    description = text,
    tags = new_list(),
    original_text = text,
  }
  setmetatable(item, {
    __tostring = function(t)
      -- return t.original_text
      local text = ""
      if t.complete then
        text = "x "
      end
      if t.priority < 27 then
        local priorities = "ABCDEFGHIJKLMNOPQRSTUVWXYZ"
        text = text .. "(" .. text:sub(t.priority, t.priority) .. ") "
      end
      if t.completion_date then
        text = text .. t.completion_date .. " "
      end
      if t.creation_date then
        text = text .. t.creation_date .. " "
      end
      text = text .. description
      return text
    end,
  })

  if text:sub(1, 2) == "x " then
    item.complete = true
    text = text:sub(3)
  end
  -- NOTE I am not sure what this is doing exactly. This might be what is breaking parse_item.
  --  This pattern is using a capture but expecting an integer result. That probably shouldn't be possible.
  --  Also, this pattern.. should be capturing what is needed, why do we manually grab it after catching it?
  if text:find("%(%u%) ") == 1 then
    local priorities = "ABCDEFGHIJKLMNOPQRSTUVWXYZ"
    local priority = priorities:find(text:sub(2, 2))
    if priority then
      item.priority = priority
    end
    text = text:sub(5)
  end
  if text:find(patterns.date) == 1 then
    -- this is one of two dates potentially
    local date = text:sub(1, 10)
    text = text:sub(12)
    if text:find(patterns.date) == 1 then
      -- if two dates are specified, the first is completion_date, the second is creation_date
      item.completion_date = date
      item.creation_date = text:sub(1, 10)
      text = text:sub(12)
    else
      -- if only one date is specified, it is the creation_date
      item.creation_date = date
    end
  end
  item.tags = get_tags(text)
  item.description = text

  return item
end

local function add_item(list, text)
  -- local item = parse_item(text) -- BUG somehow doesn't work
  -- if not item.creation_date then
  --   item.creation_date = os.date("%Y-%m-%d")
  -- end
  -- table.insert(list, tostring(item))

  -- TEMP this doesn't handle priorities correctly! priorities come before dates
  if not (text:find(patterns.date) == 1) then
    text = os.date("%Y-%m-%d") .. " " .. text
  end

  local last_index = 0
  for index, item in pairs(list) do
    if index > last_index then last_index = index end
  end
  
  list[last_index + 1] = text
end

local items = load()

local function documented_function(doc, fn)
  local t = {}
  setmetatable(t, {
    __tostring = function() return doc end,
    __call = function(t, ...) return fn(...) end,
  })
  return t
end

local function filter(list, criteria)
  local filtered_list = new_list()
  for index, item in pairs(items) do
    if criteria(item) then
      filtered_list[index] = item
    end
  end
  return filtered_list
end

local commands = {
  add = documented_function("Adds a new item.", function(arguments)
    if not arguments then error("Tried to add an empty item?") end
    add_item(items, table.concat(arguments, " "):gsub("\n", " "))
    save(items)
    print(#items, items[#items])
  end),
  list = documented_function("Lists items with filtering. Shows only incomplete items by default.", function(arguments)
    -- TODO allow filtering
    local function is_complete(item)
      return not (item:sub(1, 2) == "x ")
    end
    local complete_items = filter(items, is_complete)
    print(complete_items)
  end),
  help = documented_function("Shows all available commands.", function(arguments)
    -- TODO allow filtering / more in-depth documentation
    local documentation = new_list()
    for name, fn in pairs(commands) do
      table.insert(documentation, name .. ": " .. tostring(fn))
    end
    table.sort(documentation)
    print(documentation)
  end),
}

local command = arg[1]
if not command then
  commands.list()
  os.exit()
end

local arguments = {}
for i = 2, #arg do
  table.insert(arguments, arg[i])
end

if commands[string.lower(command)] then
  commands[string.lower(command)](arguments)
else
  print("\"" .. tostring(command) .. "\" is not a valid command.")
  commands.help()
end
