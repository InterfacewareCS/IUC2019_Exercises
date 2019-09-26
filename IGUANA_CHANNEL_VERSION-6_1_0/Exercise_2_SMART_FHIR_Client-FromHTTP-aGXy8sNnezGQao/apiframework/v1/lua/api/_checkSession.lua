-- _checkSession 
-- This is used by the API GUI for giving access tokens.

local InvalidSession = require 'apiframework.v1.lua.util.invalidSession'
local Check          = require 'apiframework.v1.lua.util.checkSession'

local function CheckSession(R,A)
   iguana.logInfo('CHECKING SESSION');
   local Valid, User, Expiry = Check(R)
   if (not Valid) then
      return InvalidSession();
   else
      return {Success=true, Data={Name=User, ExpireTime=Expiry}}
   end   
end

return CheckSession