-- _listTokens returns a list of all the Access tokens
-- This is used to power the GUI used to administer setting up access tokens.

local data = require 'database_driver'
local CheckSession = require 'apiframework.v1.lua.util.checkSession'
local InvalidSession  = require 'apiframework.v1.lua.util.invalidSession'

local ListTokens = function(R)
   if not CheckSession(R) then
      return InvalidSession()
   end
   local Result = data.ListAccessTokens()
   return {Success=true, TokenList=Result}
end

return ListTokens