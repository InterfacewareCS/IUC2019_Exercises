-- _logout
-- This is used by GUI to destroy the session created by _login

local data = require 'database_driver'
local GetSessionKey = require 'apiframework.v1.lua.util.getSessionKey'

local function Logout(R,A)
   local SessionKey = GetSessionKey()
   if (not R.cookies[SessionKey]) then
      return {Success=true, Message="Session already removed."}
   end
   local SessionId = R.cookies[SessionKey]
   data.DeleteSession(SessionId)
   return {Success=true, Message="Logged you out."}
end

return Logout