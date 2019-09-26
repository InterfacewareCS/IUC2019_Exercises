-- _generateToken
-- This is used by the GUI used to create Access tokens.

local data = require 'database_driver'
local CheckSession = require 'apiframework.v1.lua.util.checkSession'
local InvalidSession = require 'apiframework.v1.lua.util.invalidSession'

local GenerateToken = function(R)
   if not CheckSession(R) then
      return InvalidSession()
   end
   local Name = R.params.Name
   if (not Name) then
      return {Success=false, Message="Specify a Name."}
   end
   if data.CheckAccessTokenNameExists(Name) then
      return {Success=false, Message="Enter a unique name"}
   end
   
   local Token = filter.base64.enc(filter.hex.dec(util.guid(256)))
   data.InsertNewAccessToken(Name, Token)
   return {Success=true}
end

return GenerateToken