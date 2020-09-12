-- rc --

local rc = {}

function rc.start(svc)
  local ok, err = loadfile(string.format("/etc/rc.d/%s.lua", svc))
end

function rc.stop()
  error("stopping services is not implemented", 0)
end

return rc
