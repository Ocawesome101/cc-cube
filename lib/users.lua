-- users --

local kernel = kernel
_G.kernel = nil
package.loaded.thread = kernel.thread

local users = {}

-- TODO: actually verify things and whatnot
function users.login()
  return true
end

package.loaded.users = users
