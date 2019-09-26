-- Call GET /sessionid
--[[ Returns a list of session ID's from the Database.]]
local sqlDB = require('database_driver')
local hFunctions = require ('helper')
function Sessionid(Call, App)
   local Result = Call.response()

   -- TODO Write code to look at Call data and populate Result
   local datab = sqlDB.ListServerAccessToken()

   local datab = sqlDB.ListServerAccessToken()
   for i=1, #datab do  
      Result.data[i] = datab[i]
   end

   return Result
end

return Sessionid