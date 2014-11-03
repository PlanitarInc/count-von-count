local referer = {}
local socket_url = require "bonus.net.url"

function referer:init()
end

function referer:AddtoArgsFromNginx(args)
  referer:fromString(args, ngx.req.get_headers()["referer"])
end

function referer:AddToArgsFromLogPlayer(args, line)
  referer:fromString(args)
end

function referer:fromString(args, url)
  local parsed_url = socket_url.parse(url)
  if parsed_url and parsed_url.scheme then
    args["referer_host"] = parsed_url.host
  else
    args["referer_host"] = ""
  end
  if parsed_url and parsed_url.scheme and parsed_url.host then
    args["referer"] = parsed_url.scheme .. "://" .. parsed_url.host .. (parsed_url.path or "")
  else
    args["referer"] = ""
  end
end

return referer
