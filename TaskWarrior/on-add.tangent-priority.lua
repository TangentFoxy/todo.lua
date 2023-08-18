#!/usr/bin/env luajit

local cjson = require("cjson")

local function get_file_name(file_path)
  local index = file_path:match("^.+()/")
  if index then
    return file_path:sub(index + 1)
  else
    return file_path
  end
end

local function iso8601_to_seconds(iso8601_timestamp)
  local year, month, day, hour, minute, second = iso8601_timestamp:match("(%d%d%d%d)(%d%d)(%d%d)T(%d%d)(%d%d)(%d%d)Z")
  local timestamp = os.time{
    year = tonumber(year),
    month = tonumber(month),
    day = tonumber(day),
    hour = tonumber(hour),
    min = tonumber(minute),
    sec = tonumber(second),
    isdst = false,
  }
  return timestamp
end

if arg[1] == "api:2" then
  local task = cjson.decode(io.read())

  -- based on Reddit's hot sorting method
  local time = iso8601_to_seconds(task.modified) - 1134028003
  -- 1 to 27 (no priority to priority A)
  local score = 1
  if task.priority then
    score = 1 + ("ZYXWVUTSRQPONMLKJIHGFEDCBA"):find(task.priority)
  end
  task.tanpri = math.log(score) + time / 86400 -- decay period of 1 day

  print(cjson.encode(task))
else
  io.stderr:write(get_file_name(arg[0]) .. " was written for TaskWarrior Hooks v2.\n")
end
