-- Call GET /session
--[[ Returns a list of session ID's from the Database.]]
local sqlDB = require('database_driver')
local hFunctions = require ('helper')
function Session(Call, App)
   local Result = Call.response()

   local datab = sqlDB.ListServerAccessToken()
   
   if datab then
      for i=1, #datab do  
         Result.data[i] = datab[i]
      end
   end
   
   return Result
end

return Session