-- CUBE-init --

local init = {_VERSION = "cuberc 0.1.0"}
local kernel = kernel

local colors = {
  FAIL = 91,
  OK = 92,
  WARN = 93,
  INFO = 94,
}
function init.log(status, msg)
  if not msg then msg = status status = "INFO" end
  kernel.console.write(string.format("\27[%d;49m*\27[97m %s\27[37m", colors[status] or status, msg))
end

function init.panic(msg)
  msg = msg or ""
  init.log("FAIL", msg.."\n")
  kernel.panic("attempted to kill init!")
end

init.log("INFO", string.format("\27[97;49mStarting \27[92m%s\27[97m on \27[93m%s\27[39m\n", init._VERSION, _HOST))

init.log("Setting up basic helper functions...")
function _G.dofile(file)
  expect(1, file, "string")
  return select(2, assert(pcall(assert(loadfile(file)))))
end
local w, h = term.getSize()
local function done(stat, col)
  stat = stat or "OK"
  kernel.console.write(string.format("\27[%dm%s\27[37m\n", colors[stat] or col or 92, stat))
end
done()

do
  local libs = {
    "io",
    "package",
    "os",
    "users"
  }
  local fail = false
  for i=1, #libs, 1 do
    init.log(string.format("Set up %s...", libs[i]))
    local ok, err = pcall(dofile, string.format("/lib/%s.lua", libs[i]))
    if not ok and err then
      fail = err
      done("FAIL")
      break
    end
    done()
  end
  if fail then init.panic(fail) end
end


