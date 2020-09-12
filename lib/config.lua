-- config --

local s = require("serialization")

local ser = s.serialize
local uns = s.deserialize

local config = {}

function config.load(file, defaults)
  expect(1, file, "string")
  expect(2, defaults, "table", "nil")
  defaults = defaults or {}

  local handle, err = io.open(file, "r")
  if not handle then
    return {}, err
  end
  local data = handle:read("*a")
  handle:close()

  local cfg = uns(data)
  if not cfg then cfg = {} end

  for k, v in pairs(defaults) do
    cfg[k] = cfg[k] or v
  end

  return cfg
end

function config.save(cfg, file)
  expect(1, cfg, "table")
  expect(2, file, "string")

  local sv, err = ser(cfg)
  if not sv then
    return nil, err
  end

  local handle, err = io.open(file, "w")
  if not handle then
    return nil, err
  end
  handle:write(sv)
  handle:close()
  return true
end

return config
