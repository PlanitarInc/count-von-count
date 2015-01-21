local utils = require "utils"
local cjson = require "cjson"

local args = utils:normalizeKeys(ngx.req.get_query_args())
local red = utils:initRedis()

function today(hour)
  local t = os.date("*t", os.time())
  t.sec = 0
  t.min = 0
  t.hour = hour or 0
  return os.time(t)
end

function getPrefix(igid, args)
  -- "stats:(iguide|view):<id>:<granularity>[:dsname]:<groupby>:<timestamp>
  local prefix = "stats:iguide:" .. tostring(igid) .. ":" .. args["gran"]
  if args["dsname"] then
    prefix = prefix .. ":" .. args["dsname"]
  end
  prefix = prefix .. ":" .. args["groupby"]
  return prefix
end

function redisArray2keyValue(arr)
  local kv = {}
  for i = 1, #arr, 2 do
    local k, v = tostring(arr[i]), arr[i+1]
    if type(v) == "table" then
      v = redisArray2keyValue(v)
    else
      v = tonumber(v) or v
    end
    kv[k] = v
  end
  return kv
end

function processResponse(res)
  local attributes = args["attr"]
  local obj = {
    ["time"] = {},
  }

  if not attributes then
    -- extract the attributes from response
    attributes = {}
    for i = 2, #res, 2 do
      for j = 2, #res[i], 2 do
        local a = res[i][j-1]
        if not obj[a] then
          obj[a] = {}
          table.insert(attributes, a)
        end
      end
    end
  elseif type(attributes) ~= "table" then
    attributes = { attributes }
  end

  for i = 1, #attributes, 1 do
    obj[attributes[i]] = {}
  end

  for i = 2, #res, 2 do
    local idx = i / 2
    local time = tonumber(res[i - 1])
    local values = res[i]

    obj["time"][idx] = time
    for j, a in ipairs(attributes) do
      obj[a][idx] = 0
    end

    for j = 2, #values, 2 do
      local a = values[j-1]
      local v = tonumber(values[j])
      obj[a][idx] = v
    end
  end

  return obj
end

function getIGuideValues(igid, args)
  args["prefix"] = getPrefix(igid, args)
  local res = red:evalsha(ngx.var.redis_getdaterange_hash, 0, cjson.encode(args))
  return processResponse(res)
end

function parseDate(str)
  local y, m, d, h

  y, m, d, h = str:match("(%d%d%d%d)-(%d%d)-(%d%d)-(%d%d)")
  if y and m and d and h then
    return utils:utctime({year = y, month = m, day = d, hour = h}) 
  end

  y, m, d = str:match("(%d%d%d%d)-(%d%d)-(%d%d)")
  if y and m and d then
    return utils:utctime({year = y, month = m, day = d, hour = 0}) 
  end

  y, m = str:match("(%d%d%d%d)-(%d%d)")
  if y and m then
    return utils:utctime({year = y, month = m, day = 1, hour = 0}) 
  end

  y, m = str:match("(%d%d%d%d)")
  if y then
    return utils:utctime({year = y, month = 1, day = 1, hour = 0}) 
  end

  return nil
end

function parseDuration(str)
  return utils:duration(str .. "_sec")
end

args["start"] = args["startdate"] and parseDate(args["startdate"]) or args["start"]
args["startdate"] = nil
args["end"] = args["enddate"] and parseDate(args["enddate"]) or args["end"]
args["enddate"] = nil
args["step"] = args["step"] and parseDuration(args["step"]) or args["step"]

local default_values = {
  ["gran"] = "hourly",
  ["groupby"] = "all",
  ["format"] = "!%Y-%m-%d-%H",
  ["start"] = today(),
  ["end"] = today(23),
  ["step"] = utils:duration("hour_sec"),
}
setmetatable(args, { __index = default_values })

-- Make sure essential arguments are set
for i, v in ipairs({"format", "start", "end", "step"}) do
  args[v] = args[v]
end

local response = {}
local igid = args["igid"]
if type(igid) == "table" then
  for i, id in ipairs(igid) do
    response[id] = getIGuideValues(id, args)
  end
elseif igid then
  response = getIGuideValues(igid, args)
end

if type(response) == "table" then
  response = cjson.encode(response)
end
ngx.say(response)
