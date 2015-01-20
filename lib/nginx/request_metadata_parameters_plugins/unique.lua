local unique = {}

function unique:init()
end

function unique:AddtoArgsFromNginx(args)
  unique:fromString(args)
end

function unique:AddToArgsFromLogPlayer(args)
  unique:fromString(args)
end

function unique:fromString(args)
  if args["repeated"] then
    args["unique"] = "repeated"
  else
    args["unique"] = "unique"
  end
end

return unique
