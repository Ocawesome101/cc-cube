-- startup --

local bootPath = os.getBootPath()

local kernel = "/boot/cube.lua"

local handle, err = fs.open(kernel, "r")
if not handle then
  error(err)
end

local data = handle.readAll()
handle.close()

local ok, err = load(data, "="..kernel, "bt", _G)
if not ok then
  error(err)
end

local s, r = xpcall(ok, debug.traceback())
if not s and r then
  error(r)
end
