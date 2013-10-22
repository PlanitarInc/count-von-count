-------------- Function to simulate inheritance -------------------------------------
-- local function inheritsFrom( baseClass )
--   local new_class = {}
--   local class_mt = { __index = new_class }

--   if baseClass then
--     setmetatable( new_class, { __index = baseClass } )
--   end

--   return new_class
-- end

-------------- Base Class  ---------------------------------------------------------

local Base = {}

function Base:new(_obj_type, ids, _type)
  local redis_key = _obj_type
  for k, id in ipairs(ids) do
    redis_key = redis_key .. "_" .. id
  end
  local baseObj = { redis_key = redis_key, _type = _type}
  self.__index = self
  return setmetatable(baseObj, self)
end


function Base:count(key, num)
  if self._type == "set" then
    redis.call("ZINCRBY", self.redis_key, num, key)
  else
    redis.call("HINCRBY", self.redis_key, key, num)
  end
end

------------- Helper Methods ------------------------

-- return an array with all the values in tbl that match the given keys array
local function getValueByKeys(tbl, keys)
  local values = {}
  if type(keys) == "table" then
    for i, key in ipairs(keys) do
      table.insert(values, tbl[key])
    end
  else
    table.insert(values, tbl[keys])
  end
  return values
end

-- parse key and replace "place holders" with their value from tbl
local function addValuesToKey(tbl, key)
  local rslt = key
  local match = rslt:match("{%w*}")
  while match do
    local subStr = tbl[match:sub(2, -2)]
    rslt = rslt:gsub(match, subStr)
    match = rslt:match("{%w*}")
  end
  return rslt
end

--------------------------------------------------

local params = cjson.decode(ARGV[1])
local config = cjson.decode(ARGV[2])
local action = params["action"]
local defaultMethod = { count = action, change = 1 }

local action_config = config[action]
if action_config then
  for obj_type, methods in pairs(action_config) do
    for i, defs in ipairs(methods) do
      setmetatable(defs, { __index = defaultMethod })
      local ids = getValueByKeys(params, defs["id"])
      local key = addValuesToKey(params, defs["count"])
      local change = defs["change"]
      local _type = defs["type"] or "hash"

      local obj = Base:new(obj_type, ids, _type)
      obj:count(key, change)
    end
  end
end