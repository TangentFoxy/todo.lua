#!/usr/bin/env luajit

math.randomseed(os.time())

-- NOTE not in use anymore
local function print_stuff(object)
  if type(object) == "table" then
    for index, value in ipairs(object) do
      print(index, value)
    end
  else
    print(object)
  end
end

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
      for index, value in ipairs(t) do
        table.insert(output, pad(leftpad(index, 4), 8) .. tostring(value))
      end
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
  local tags
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
      for _, token in ipairs(tokens) do
        local index = token:find(tag_type)
        if index then
          table.insert(tags, token:sub(1, index))
        end
      end
    else
      for _, token in ipairs(tokens) do
        if token:find(tag_type) == 1 then
          table.insert(tags, token)
        end
      end
    end

    return tags
  end

  local function append(recipient_list, source_list)
    if not (type(recipient_list) == "table" and type(source_list) == "table") then
      error("append() only accepts tables.")
    end

    for _, item in ipairs(source_list) do
      table.insert(recipient_list, item)
    end
    return recipient_list
  end

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
        tags = append(tags, parse(tokens, tag)) -- I hate this
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

  for _, item in ipairs(list) do
    file:write(item .. "\n")
  end
  file:close()
end

local function add_item(list, text)
  -- TEMP this doesn't handle priorities correctly!
  -- TODO split into tokens, check and discard priority,
  --  check and discard completion?,
  --  check and implement..however
  if not (text:find("%d%d%d%d%-%d%d%-%d%d") == 1) then
    text = os.date("%Y-%m-%d") .. " " .. text
  end
  table.insert(list, text)
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

local commands = {
  add = documented_function("Adds a new item.", function(arguments)
    if not arguments then error("Tried to add an empty item?") end
    add_item(items, table.concat(arguments, " "):gsub("\n", " "))
    save(items)
    print(#items, items[#items])
  end),
  list = documented_function("Lists items with filtering. Shows only incomplete items by default.", function(arguments)
    -- TODO allow filtering (default should be incomplete items only)
    --  this requires a lot of parsing, can't use the tostring() method
    --  remember to filter AFTER numbering, so that numbering is preserved
    print(items)
  end),
  help = documented_function("", function(arguments)
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
