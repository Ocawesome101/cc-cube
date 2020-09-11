-- os --

local thread = kernel.thread

function os.getenv(k)
  expect(1, k, "string", "number")
  local env = thread.info().env
  return env[k]
end

function os.setenv(k, v)
  expect(1, k, "string", "number")
  expect(2, v, "string", "number")
  local env = thread.info().env
  env[k] = v
  return true
end
