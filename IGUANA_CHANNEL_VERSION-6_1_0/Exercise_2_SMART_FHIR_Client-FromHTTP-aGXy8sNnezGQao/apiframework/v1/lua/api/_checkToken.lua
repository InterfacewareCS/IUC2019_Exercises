-- _checkToken 
-- Can be used to check if an access token is valid.

local Check = require 'apiframework.v1.lua.util.checkToken'

local CheckToken = function(R)
   local Success = Check(R)
   if not Success then
      return {error="Invalid Token", code=401}
   end
   
   return {Success=true}
end

return CheckToken