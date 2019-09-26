local data = require 'database_driver'
local GetSessionKey = require 'apiframework.v1.lua.util.getSessionKey'

local function CheckSession(R)
   local SessionKey = GetSessionKey()
   local Session = R.cookies[SessionKey]
   if (not Session) then
      return false
   end
   iguana.logInfo("CheckSession="..Session)
   
   local ValidSession, UserId, Expiry = data.IsSessionValid(Session)
   if not ValidSession then
      return false
   end
   
   if (not iguana.isTest() and Expiry < os.ts.time()) then
      return false   
   end
   local Expiry = (Expiry - os.ts.time() - 10) *1000
   return true ,UserId,Expiry
end
 
return CheckSession
      