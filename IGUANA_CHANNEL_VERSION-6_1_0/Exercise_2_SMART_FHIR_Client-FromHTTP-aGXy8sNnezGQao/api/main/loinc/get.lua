-- Call GET /loinc
--[[ Returns a lookup table with loinc codes.]]
local sqlDB = require('database_driver')

function Loinc(Call, App)
   local Result = Call.response()
   
   -- TODO Write code to look at Call data and populate Result
   local datab = sqlDB.ListLoinc()
   
   if datab then
      for i=1, #datab do  
         Result.data[i] = datab[i]
      end
   end
   return Result
end

return Loinc