-- the Computercraft Universal Best Environment --
-- TODO TODO TODO: a better name!

local start = os.epoch("utc")
local bootPath = os.getBootPath()

_G.kernel = {}

-- logger
do
  local set = term.set
  local y = 0
  local w, h = term.getSize()
  local function log(msg)
    if y > h then
      y = h
      term.scroll(1)
    else
      y = y + 1
    end
    term.set(1, y, msg)
  end
  term.clear()
  function kernel.log(msg)
    for ln in msg:gmatch("[^\n]+") do
      log(string.format("[%4.4f] %s", os.epoch("utc") - start, ln))
    end
  end
end

kernel.log("booted!")
