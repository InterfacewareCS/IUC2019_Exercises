-- _saveClientId
-- Save the Client ID

local data = require 'database_driver'
local CheckSession = require 'apiframework.v1.lua.util.checkSession'

local RemoveToken = function(R)
   if not CheckSession(R) then
      return InvalidSession()
   end
   
   local ClientId = R.params.client_id
   local ClientUrl = R.params.app_location
   if (not ClientId or #ClientId == 0) then
      return {Success=false, Message="Need client_id parameter"}
   end
   
   local DB = data.SetClient(ClientId, ClientUrl)
   
   trace(data.GetClient())
   
   return {Success=true}
end

return RemoveToken