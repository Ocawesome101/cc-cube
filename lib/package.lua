-- package --

_G.package = {}

local fs = fs
local loaded = {
  _G = _G,
  io = io,
  fs = fs,
  os = os,
  math = math,
  table = table,
  bit32 = bit32,
  string = string,
  package = package,
  coroutine = coroutine,
  filesystem = filesystem
}
local loading = {}
_G.term = nil
_G.fs = nil
package.loaded = loaded

package.path = "/lib/?.lua;/lib/lib?.lua;/usr/lib/?.lua;/usr/lib/lib?.lua"

function package.searchpath(name, path, sep, rep)
  expect(1, name, "string")
  expect(2, path, "string")
  expect(3, sep,  "string", "nil")
  expect(4, rep,  "string", "nil")
  sep = "%" .. (sep or ".")
  rep = rep or "/"
  local searched = {}
  name = name:gsub(sep, rep)
  for search in path:gmatch("[^;]+") do
    search = search:gsub("%?", name)
    if fs.exists(search) then
      return search
    end
    searched[#searched + 1] = search
  end
  return nil, (string.format(("\n\tno file '%s'"):rep(#searched):sub(3),
                                                        table.unpack(searched)))
end

function _G.require(mod)
  expect(1, mod, "string")
  if loaded[mod] then
    return loaded[mod]
  elseif not loading[mod] then
    local lib, status, step
    
    step, lib, status = "not found", package.searchpath(mod, package.path, ".", "/")

    if lib then
      step, lib, status = "loadfile failed", loadfile(lib)
    end

    if lib then
      loading[mod] = true
      step = "load failed"
      local ok, err = pcall(lib, mod)
      if not ok then
        lib = nil
        status = err
      else
        lib = err
        status = ""
      end
      loading[mod] = false
    end

    assert(lib, string.format("module '%s' %s:\n%s", mod, step, status))
    loaded[mod] = status
    return lib
  else
    error(string.format("already loading: %s\n%s", mod, debug.traceback(), 2))
  end
end
