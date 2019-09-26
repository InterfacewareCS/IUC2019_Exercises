-- _removeToken 
-- This call is used by the GUI to remove an access token.

local data = require 'database_driver'
local CheckSession = require 'apiframework.v1.lua.util.checkSession'

local RemoveToken = function(R)
   if not CheckSession(R) then
      return InvalidSession()
   end
   
   local TokenId = R.params.TokenId
   if (not TokenId) then
      return {Success=false, Message="Need TokenId parameter"}
   end
   
   local DB = data.DeleteAccessToken(TokenId)
   
   return {Success=true}
end

return RemoveToken

