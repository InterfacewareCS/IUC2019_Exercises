local data = require 'database_driver'
local CheckSession = require 'apiframework.v1.lua.util.checkSession'


local AuthorizationHeader = [[
Please use HTTP header:
Authorization: Bearer <access token>]]

local function CheckToken(R)
   if R.headers['Authorization'] == nil then 
      if CheckSession(R) then
         -- We allow sessions to be used for authentication in order to allow people
         -- to access the API through the browser.
         return true
      end
      return false, AuthorizationHeader 
   end
   local Auth = R.headers['Authorization']
   if Auth:sub(1,6) ~= 'Bearer' then 
      return false, AuthorizationHeader.."\n\nHeader supplied was:\nAuthorization: "..R.headers.Authorization 
   end
   local List = Auth:split(' ')
   if #List < 2 then 
      return false, AuthorizationHeader.."\n\nUnable to parse out the access token.\nHeader supplied was:\nAuthorization: "..R.headers.Authorization 
   end
   local Token = List[#List]
   if not data.IsTokenValid(Token) then
      return false, "Access token '"..Token.."' not valid."   
   end  
   return true
end

return CheckToken
