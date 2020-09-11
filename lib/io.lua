-- io library --

_G.io = {}
local thread = kernel.thread
local fs = fs

local function streamify(thing)
  return {
    read = function(self, amt)
      if type(amt) == "string" then
        amt = amt:gsub("%*", "")
      end
      if amt == "a" then
        return thing.readAll and thing.readAll() or thing.read(math.huge)
      elseif amt == "l" then
        return thing.readLine and thing.readLine() or thing.read()
      end
      return thing.read(amt)
    end,
    write = function(self, ...)
      return thing.write(...)
    end,
    close = function(self, ...)
      if thing.close then thing.close() end
      return true
    end
  }
end
io.streamify = streamify

setmetatable(io, {
  __index = function(t, k)
    if k == "stdin" then
      return thread.info().io.i
    elseif k == "stdout" then
      return thread.info().io.o
    elseif k == "stderr" then
      return streamify(kernel.console)
    end
  end
})

function io.open(file, mode)
  expect(1, file, "string")
  expect(2, mode, "string", "nil")
  local ok, err = fs.open(file, mode or "r")
  if not ok then
    return nil, err
  end
  return streamify(ok)
end

local function set(k, v, m)
  expect(1, v, "string", "table")
  if type(v) == "string" then
    local err
    v, err = io.open(v, m or "r")
    if not v then
      return nil, err
    end
  end
  thread.info().io[k] = v
  return thread.info().io[k]
end

function io.output(s)
  return set("o", s, "w")
end

function io.input(s)
  return set("i", s, "r")
end

function io.write(...)
  local args = table.pack(...)
  for i=1, args.n, 1 do
    expect(i, args[i], "string", "number")
  end
  return io.output():write(write)
end

function io.read(...)
  return io.input():read(...)
end
