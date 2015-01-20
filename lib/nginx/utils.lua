local redis = require "resty.redis"
local utils = {}

function utils:normalizeKeys(tbl)
  local normalized = {}
  for k, v in pairs(tbl) do
    local key = k:gsub("amp;", "")
    local value = v
    if key:match("[[]]") then
      key = key:gsub("[[]]", "")
      if type(value) ~= "table" then
        value = { v }
      end
    end
    normalized[key] = value
  end
  return normalized
end

function utils:initRedis()
  local red = redis:new()
  red:set_timeout(3000) -- 3 sec
  local ok, err = red:connect(SYSTEM_CONFIG["redis_host"], SYSTEM_CONFIG["redis_port"])
  if not ok then utils:logErrorAndExit("Error connecting to redis: ".. err) end
  return red
end

function utils:loadSystemConfig()
  config_path = "/opt/openresty/nginx/count-von-count/config/system.config"
  SYSTEM_CONFIG = {}
  for line in io.lines(config_path) do
    for i,j in line:gmatch("(%S+):%s*(%S+)") do
      SYSTEM_CONFIG[i] = j
    end
  end
end

function utils:logErrorAndExit(err)
   ngx.log(ngx.ERR, err)
   utils:emptyGif()
end

function utils:emptyGif()
  ngx.exec('/_.gif')
end

function utils:utctime(t)
  return os.time(t) - os.time({year=1970, month=1, day=1, hour=0})
end

local durations = {
  ["min_sec"]   =                60,
  ["hour_sec"]  =           60 * 60,
  ["day_sec"]   =      24 * 60 * 60,
  ["week_sec"]  =  7 * 24 * 60 * 60,
  ["month_sec"] = 30 * 24 * 60 * 60, -- XXX good enough
}
function utils:duration(d)
  return durations[d]
end

return utils
