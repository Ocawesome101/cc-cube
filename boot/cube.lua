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
    kernel.logY = y
  end
  term.clear()
  function kernel.log(msg)
    for ln in msg:gmatch("[^\n]+") do
      log(string.format("[%4.4f] %s", (os.epoch("utc") - start) / 1000, ln))
    end
  end
  function kernel.panic(msg)
    kernel.log("-- KERNEL PANIC --")
    kernel.log(debug.traceback(msg, 1):gsub("\t", "  "))
    kernel.log("-- END TRACE --")
    while true do coroutine.yield() end
  end
end

kernel.log("Starting " .. kernel._VERSION .. " on " .. _VERSION)

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

  kernel.log("kevent: compatibility: os.pullEvent")
  os.pullEvent = event.pull
  kernel.log("kevent: compatibility: kernel.event.push")
  event.push = os.pushEvent
  
  kernel.event = event
end

kernel.log("vt100: initialize")
do
  kernel.log("vt100: note: colors may be off on non-\ncolor terminals")
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
    4096,
    8192,
    16384,
    32768
  }

  -- keys: mostly copy-pasted from CraftOS
  kernel.log("vt100: note: key codes are subject to \nchange without warning due to Minecraft \nupdates.")
  kernel.log("vt100: note: please open an issue if this\nhappens!")
  local keys = {
    nil,            "1",            "2",            "3",            "4",            -- 1
    "5",            "6",            "7",            "8",            "9",            -- 6
    "0",            "-",            "=",            "\8",           "\t",           -- 11
    "q",            "w",            "e",            "r",            "t",            -- 16
    "y",            "u",            "i",            "o",            "p",            -- 21
    "[",            "]",            "\13",          "leftCtrl",     "a",            -- 26
    "s",            "d",            "f",            "g",            "h",            -- 31
    "j",            "k",            "l",            ";",            "'",            -- 36
    "`",            "leftShift",    "\\",           "z",            "x",            -- 41
    "c",            "v",            "b",            "n",            "m",            -- 46
    ",",            ".",            "/",            "rightShift",   "*",            -- 51
    "leftAlt",      " ",            "capsLock",     "f1",           "f2",           -- 56
    "f3",           "f4",           "f5",           "f6",           "f7",           -- 61
    "f8",           "f9",           "f10",          "numLock",      "scrollLock",   -- 66
    "numPad7",      "numPad8",      "numPad9",      "numPadSubtract","numPad4",     -- 71
    "numPad5",      "numPad6",      "numPadAdd",    "numPad1",      "numPad2",      -- 76
    "numPad3",      "numPad0",      "numPadDecimal",nil,            nil,            -- 81
    nil,            "f11",          "f12",          nil,            nil,            -- 86
    nil,            nil,            nil,            nil,            nil,            -- 91
    nil,            nil,            nil,            nil,            "f13",          -- 96
    "f14",          "f15",          nil,            nil,            nil,            -- 101
    nil,            nil,            nil,            nil,            nil,            -- 106
    nil,            "kana",         nil,            nil,            nil,            -- 111
    nil,            nil,            nil,            nil,            nil,            -- 116
    "convert",      nil,            "noconvert",    nil,            "yen",          -- 121
    nil,            nil,            nil,            nil,            nil,            -- 126
    nil,            nil,            nil,            nil,            nil,            -- 131
    nil,            nil,            nil,            nil,            nil,            -- 136
    "=",            nil,            nil,            "circumflex",   "@",            -- 141
    ":",            "_",            "kanji",        "stop",         "ax",           -- 146
    nil,            nil,            nil,            nil,            nil,            -- 151
    "numPadEnter",  "rightCtrl",    nil,            nil,            nil,            -- 156
    nil,            nil,            nil,            nil,            nil,            -- 161
    nil,            nil,            nil,            nil,            nil,            -- 166
    nil,            nil,            nil,            nil,            nil,            -- 171
    nil,            nil,            nil,            "numPadComma",nil,              -- 176
    "numPadDivide", nil,            nil,            "rightAlt",     nil,            -- 181
    nil,            nil,            nil,            nil,            nil,            -- 186
    nil,            nil,            nil,            nil,            nil,            -- 191
    nil,            "pause",        nil,            "home",         "\27[A",        -- 196
    "\27[5~",       nil,            "\27[D",        nil,            "\27[C",        -- 201
    nil,            "end",          "\27[B",        "\27[6~",       "insert",       -- 206
    "\127"                                                                        -- 211
  }

  local shifted = false
  local ls, rs = false
  kernel.log("vt100: WARNING: 'shift' key support is shaky")
  local shift = {
    leftShift = function(p) shifted = rs or p; ls = p end,
    rightShift = function(p) shifted = ls or p; rs = p end,
    ['.'] = ">",
    [','] = "<",
    ["'"] = '"',
    ['1'] = "!",
    ['2'] = "@",
    ['3'] = "#",
    ['4'] = "$",
    ['5'] = "%",
    ['6'] = "^",
    ['7'] = "&",
    ['8'] = "*",
    ['9'] = "(",
    ['0'] = ")",
    ['-'] = "_",
    ['='] = "+",
    ['['] = "{",
    [']'] = "}",
    ['\\']= "|",
    ['`'] = "~"
  }
  setmetatable(shift, {__index = function(t,k)
                                     if k and #k == 1 then
                                       return k:upper()
                                     else
                                       return ""
                                     end
                                   end})

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
    local lm = true
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
          if c:match("%d") then
            nb = nb .. c
          elseif c == ";" then
            p[#p+1] = tonumber(nb) or 0
            nb = ""
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
              cx = min(max(p[1] or 0, 1), w)
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
            p = {}
          end
        end
        flush()
        checkCursor()
        obj.setTextColor(fg)
        obj.setBackgroundColor(bg)
      end
    end

    local function read(n)
      expect(1, n, "number", "nil")
      if n and not lm then
        if n == math.huge then
          local t = rb
          rb = ""
          return t
        end
        while #rb < N do
          coroutine.yield()
        end
      else
        local N = n or 0
        while #rb < N or not rb:find("\n") do
          coroutine.yield()
        end
      end
      n = n or rb:find("\n")
      local ret = rb:sub(1, n)
      rb = rb:sub(n + 1)
      return ret
    end
    
    local function key(_, code)
      local c = keys[code]
      if shifted and c:sub(1,1) ~= "\27" then c = shift[c] end
      c = c or ""
      if #c > 1 and c:sub(1,1) ~= "\27" then
        if type(c) == "function" then
          c()
          c = ""
        end
        c = ""
      end
      rb = rb .. c
    end

    local function key_up(_, code)
      local c = keys[code]
      c = shift[c]
      if type(c) == "function" then c() end
    end

    kernel.event.register("key", key)
    kernel.event.register("key_up", key_up)

    return write, read
  end
end

do
  kernel.log("logger: creating VT100 term stream")
  local vtw, vtr = kernel.vtemu(term)
  kernel.log("logger: switching to VT100")
  vtw("\27["..(kernel.logY+1).."H")
  kernel.logY = nil
  kernel.console = {write = vtw, read = vtr}
  function kernel.log(msg)
    msg = tostring(msg)
    for ln in msg:gmatch("[^\n]+") do
      vtw(string.format("[%4.4f] %s\n", (os.epoch("utc") - start) / 1000, ln))
    end
  end
  kernel.log("logger: using VT100")
  kernel.log("\27[31mt\27[32mh\27[33mi\27[34ms \27[35ms\27[36mt\27[91mr\27[92mi\27[93mn\27[94mg \27[95mi\27[96ms\27[31m r\27[32ma\27[33mi\27[34mn\27[35mb\27[36mo\27[91mw\27[92m, \27[93mr\27[94mi\27[95mg\27[96mh\27[31m\27[32mt\27[33m?\27[39;49m")
end

kernel.log("vfs: initialize")
do
  -- This gets around CC's crappy default scheme of mounting disks at /diskN.
  -- TODO: rewrite to support mounting arbitrary filesystems, otherwise devfs
  -- TODO: and tmpfs and whatnot will use real disk space and I/O
  local ofs = fs
  _G.fs = {}
  local basic = ""
  local aliases = {["/"] = bootPath} -- {[vfsPath] = realPath}
  local function split(p)
    local segments = {}
    for seg in p:gmatch("[^\\/]+") do
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
      local check = table.concat(parts, "/", 1, i):gsub("[\\/]+", "/")
      local ret = table.concat(parts, "/", i + 1):gsub("[\\/]+", "/")
      if aliases[check] then
        local ensure = fs.combine(aliases[check], ret)
        if ofs.exists(ensure) then
          return ensure
        else
          break
        end
      end
    end
    return path
  end

  function fs.combine(...)
    return "/" .. (table.concat(table.pack(...), "/"):gsub("[\\/]+", "/"))
  end

  local basic = {"makeDirectory", "delete", "copy", "getCapacity", "isDir", "getSize", "getFreeSpace", "isDriveRoot", "attributes", "isReadOnly", "exists", "move"}
  for k, v in pairs(basic) do
    fs[v] = function(...)
      local args = table.pack(...)
      for kk, vv in pairs(args) do
        args[kk] = resolve(vv)
      end
      return ofs[v](table.unpack(args))
    end
  end
  function fs.open(f,m)
    return ofs.open(resolve(f), m or "r")
  end
  function fs.list(path)
    expect(1, path, "string")
    path = resolve(path)
    local isRoot = path == bootPath
    local files = ofs.list(path)
    if isRoot then -- filter out disk* entries from the rootfs
      local remove = {}
      for i=1, #files, 1 do
        for k,v in pairs(aliases) do
          if v == files[i] then
            remove[i] = true
          end
        end
      end
      for i in pairs(remove) do
        table.remove(files, i)
      end
    end
    return files
  end

  -- let's provide loadfile here too
  function loadfile(file, mode, env)
    expect(1, file, "string")
    expect(2, mode, "string", "nil")
    expect(3, env, "table", "nil")
    local handle, err = fs.open(file)
    if not handle then
      return nil, err
    end
    local data = handle.readAll()
    handle.close()
    return load(data, "="..file, mode or "bt", env or kernel.usb or _G)
  end
end

kernel.log("scheduler: initialize")
do
  -- TODO: flesh out the scheduler API
  local threads = {}
  local t = {}
  local timeout = 0.05
  local last = 0
  local cur = 0

  function t.spawn(f,n,a)
    expect(1, f, "function")
    expect(2, n, "string")
    expect(3, a, "table", "nil")
    last = last + 1
    a = a or {}
    local new = {
      parent = last - 1,
      pid = last,
      name = n,
      coro = coroutine.create(f),
      env = {},
      io = {i = a.io or kernel.console, o = a.io or kernel.console}
    }
    threads[last] = new
    return last
  end

  function t.info()
    local thd = threads[cur]
    return {
      name = thd.name,
      env = thd.env,
      io = thd.io
    }
  end

  function t.loop()
    t.loop = nil
    while #threads > 0 do
      local sig = table.pack(kernel.event.pull(timeout))
      for pid, thd in pairs(threads) do
        local ok, err = coroutine.resume(thd.coro, table.unpack(sig))
        if not ok or coroutine.status(thd.coro) == "dead" then
          if err then
            kernel.log(string.format("thread %s (PID %d) died: %s", thd.name, pid, err))
          else
            kernel.log(string.format("thread %s (PID %d) exited", thd.name, pid))
          end
          threads[pid] = nil
        end
      end
    end
    kernel.panic("all threads died")
  end
  kernel.thread = t
end

kernel.log("usb: creating userspace sandbox")
do
  function table.copy(tbl)
    expect(1, tbl, "table")
    local seen = {}
    local function copy(t)
      local ret = {}
      for k, v in pairs(t) do
        if type(v) == "table" then
          if seen[v] then
            ret[k] = seen[v]
          else
            seen[v] = true
            seen[v] = copy(v)
            ret[k] = seen[v]
          end
        else
          ret[k] = v
        end
      end
      return ret
    end
    return copy(tbl)
  end

  kernel.log("copying _G")
  kernel.usb = table.copy(_G)
  kernel.usb._G = kernel.usb
end

kernel.log("loading init from /sbin/init.lua")
local ok, err = loadfile("/sbin/init.lua", "bt", kernel.usb)
if not ok then
  kernel.panic(err)
end
kernel.thread.spawn(ok, "[init]")

kernel.thread.loop()
