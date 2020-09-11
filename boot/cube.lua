-- the Computercraft Universal Best Environment --
-- TODO TODO TODO: a better name!

local start = os.epoch("utc")
local bootPath = os.getBootPath()
local term = term
term.setCursorBlink(true)

_G.kernel = {}

kernel._VERSION = "CUBE 0.0.1"

-- VGA color palette --
do
  -- black
  -- red
  -- green
  -- brown/yellow
  -- blue
  -- purple
  -- cyan
  -- white
  local colors = {
    [1]     = 0x000000,
    [2]     = 0xaa0000,
    [4]     = 0x00aa00,
    [8]     = 0xaa5500,
    [16]    = 0x0000aa,
    [32]    = 0xaa00aa,
    [64]    = 0x00aaaa,
    [128]   = 0xaaaaaa,
    [256]   = 0x555555,
    [512]   = 0xff5555,
    [1024]  = 0x55ff55,
    [2048]  = 0xffff55,
    [4096]  = 0x5555ff,
    [8192]  = 0xff55ff,
    [16384] = 0x55ffff,
    [32768] = 0xffffff
  }
  for k,v in pairs(colors) do term.setPaletteColor(k,v) end
  term.setTextColor(128)
  term.setBackgroundColor(1)
end

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
      log(string.format("[%4.4f] %s", (os.epoch("utc") - start) / 1000, ln))
    end
  end
end

kernel.log("Starting " .. kernel._VERSION .. " on " .. _VERSION)

kernel.log("vt100: initialize")
do
  local colors = {
    1,
    2,
    4,
    8,
    16,
    32,
    64,
    128
  }

  local bright = {
    256,
    512,
    1024,
    2048,
    8192,
    16284,
    32768
  }

  function kernel.vtemu(obj)
    expect(1, obj, "table")
    local cx, cy = 1, 1
    local w, h = obj.getSize()
    obj.setCursorPos(1,1)
    obj.setCursorBlink(true)
    local wb = ""
    local rb = ""
    local nb = ""
    local mode = 0
    local ec = true
    local fg, bg = colors[8], colors[1]
    local p = {}
    local min, max = math.min, math.max

    local function checkCursor()
      if cx > w then cx, cy = 1, cy + 1 end
      if cy > h then cy = h obj.scroll(1) end
      if cx < 1 then cx, cy = w, cy - 1 end
      if cy < 1 then cy = 1 end
      obj.setCursorPos(cx, cy)
    end

    local function fill(x, y, W, H, c)
      local ln = c:rep(w)
      for i=y, y+H, 1 do
        obj.setCursorPos(x, i)
        obj.write(ln)
      end
      checkCursor()
    end

    local function flush()
      while #wb > 0 do
        checkCursor()
        local ln = wb:sub(1, w - cx + 1)
        obj.setCursorPos(cx, cy)
        obj.write(ln)
        wb = wb:sub(#ln + 1)
        cx = cx + #ln
      end
      checkCursor()
    end

    local function write(str)
      expect(1, str, "string")
      str = str:gsub("\8", "\27[D")
      for c in str:gmatch(".") do
        if mode == 0 then
          if c == "\n" then
            flush()
            cx, cy = 1, cy + 1
            checkCursor()
          elseif c == "\t" then
            wb = wb .. (" "):rep(max(1, (cx + 4) % 8))
          elseif c == "\27" then
            flush()
            mode = 1
          elseif c == "\7" then -- ascii BEL
            computer.beep(".")
          else
            wb = wb .. c
          end
        elseif mode == 1 then
          if c == "[" then
            mode = 2
          else
            mode = 0
          end
        elseif mode == 2 then
          if c:match("[%d]") then
            nb = nb .. c
          elseif c == ";" then
            if #nb > 0 then
              p[#p+1] = tonumber(nb) or 0
              nb = ""
            end
          else
            mode = 0
            if #nb > 0 then
              p[#p+1] = tonumber(nb)
              nb = ""
            end
            if c == "A" then
              cy = cy + max(0, p[1] or 1)
            elseif c == "B" then
              cy = cy - max(0, p[1] or 1)
            elseif c == "C" then
              cx = cx + max(0, p[1] or 1)
            elseif c == "D" then
              cx = cx - max(0, p[1] or 1)
            elseif c == "E" then
              cx, cy = 1, cy + max(0, p[1] or 1)
            elseif c == "F" then
              cx, cy = 1, cy - max(0, p[1] or 1)
            elseif c == "G" then
              cx = min(w, max(p[1] or 1))
            elseif c == "H" or c == "f" then
              cx, cy = min(w, max(0, p[2] or 1)), min(h, max(0, p[1] or 1))
            elseif c == "J" then
              local n = p[1] or 0
              if n == 0 then
                fill(cx, cy, w, 1, " ")
                fill(cx, cy + 1, h, " ")
              elseif n == 1 then
                fill(1, 1, w, cy - 1, " ")
                fill(cx, cy, w, 1, " ")
              elseif n == 2 then
                obj.clear()
              end
            elseif c == "K" then
              local n = p[1] or 0
              if n == 0 then
                fill(cx, cy, w, 1, " ")
              elseif n == 1 then
                fill(1, cy, cx, 1, " ")
              elseif n == 2 then
                fill(1, cy, w, 1, " ")
              end
            elseif c == "S" then
              obj.scroll(max(0, p[1] or 1))
              checkCursor()
            elseif c == "T" then
              obj.scroll(-max(0, p[1] or 1))
              checkCursor()
            elseif c == "m" then
              p[1] = p[1] or 0
              for i=1, #p, 1 do
                local n = p[i]
                if n == 0 then -- reset terminal attributes
                  fg, bg = colors[8], colors[1]
                  ec = true
                  lm = true
                elseif n == 8 then -- disable local echo
                  ec = false
                elseif n == 28 then -- enable local echo
                  ec = true
                elseif n > 29 and n < 38 then -- foreground color
                  fg = colors[n - 29]
                elseif n > 39 and n < 48 then -- background color
                  bg = colors[n - 39]
                elseif n == 39 then -- default foreground
                  fg = colors[8]
                elseif n == 49 then -- default background
                  bg = colors[1]
                elseif n > 89 and n < 98 then -- bright foreground
                  fg = bright[n - 89]
                elseif n > 99 and n < 108 then -- bright background
                  bg = bright[n - 99]
                elseif n == 108 then -- disable line mode
                  lm = false
                elseif n == 128 then -- enable line mode
                  lm = true
                end
              end
            elseif c == "n" then
              if p[1] and p[1] == 6 then
                rb = rb .. string.format("\27[%s;%sR", cy, cx)
              end
            end
          end
        end
        flush()
        checkCursor()
        obj.setTextColor(fg)
        obj.setBackgroundColor(bg)
      end
    end

    return write
  end
end

do
  kernel.log("logger: creating VT100 term stream")
  local vtw = kernel.vtemu(term)
  kernel.log("logger: switching to VT100")
  vtw("\27[5H")
  kernel.vtwrite = vtw
  function kernel.log(msg)
    for ln in msg:gmatch("[^\n]+") do
      vtw(string.format("[%4.4f] %s\n", (os.epoch("utc") - start) / 1000, ln))
    end
  end
  kernel.log("logger: using VT100")
end

kernel.log("kevent: initialize")
do
  local acts = {}
  local event = {}
  function event.register(evt, handler)
    expect(1, evt, "string")
    expect(2, handler, "function")
    table.insert(acts, {call = handler, sig = evt})
    return true
  end

  function event.pull(timeout)
    expect(1, timeout, "number", "nil")
    local timerId = timeout and  os.startTimer(timeout) or -1
    local evt = table.pack(coroutine.yield())
    if evt[1] == "timer" and evt[2] == timerId then
      return
    end
    for k, act in pairs(acts) do
      if act.sig == evt[1] then
        local ok, err = pcall(act.call, table.unpack(evt))
        if not ok and err then
          kernel.log("kevent: listener error: " .. err)
          acts[k] = nil
        end
      end
    end
    return table.unpack(evt)
  end

  os.pullEvent = event.pull
  event.push = os.pushEvent
  
  kernel.event = event
end

kernel.log("vfs: initialize")
do
  local ofs = fs
  _G.fs = {}
  local basic = ""
  local alias = {["/"] = "/"} -- etc, etc
  local function split(p)
    local segments = {}
    for seg in p:gmatch("[^/]+") do
      if seg == ".." then
        table.remove(segments, #segments)
      else
        table.insert(segments, seg)
      end
    end
    return segments
  end

  local function resolve(path)
    local parts = split(path)
    table.insert(parts, 1, "/")
    for i=#parts, 1, -1 do
      local check = ""
    end
  end
end

while true do kernel.event.pull() end
