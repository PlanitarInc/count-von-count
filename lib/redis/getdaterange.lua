local args = cjson.decode(ARGV[1])

local function getKey(timestamp, args) 
  return args["prefix"] .. ":" .. os.date(args["format"], timestamp)
end

local function merge2(arr1, arr2)
  local L = #arr1 > #arr2 and #arr1 or #arr2
  local res = {}
  for i = 1, L, 1 do
    table.insert(res, arr1[i])
    table.insert(res, arr2[i])
  end
  return res
end

local function getValue(key, attributes)
  if redis.call("TYPE", key).ok == "zset" then
    local from = args["from"] or 0
    local to = args["to"] or -1
    return redis.call("ZREVRANGE", key, from, to, "withscores")
  end

  local attributes = args["attr"]
  if not attributes then
    return redis.call("HGETALL", key)
  end

  if type(attributes) ~= "table" then
    return {attributes, redis.call("HGET", key, attributes)}
  end

  return merge2(attributes, redis.call("HMGET", key, unpack(attributes)))
end

local starttime = args["start"]
local endtime = args["end"]
local steptime = args["step"]

local res = {}
for currtime = starttime, endtime, steptime do
  local key = getKey(currtime, args)
  local value = getValue(key, args)
  table.insert(res, currtime)
  table.insert(res, value)
end
return res
