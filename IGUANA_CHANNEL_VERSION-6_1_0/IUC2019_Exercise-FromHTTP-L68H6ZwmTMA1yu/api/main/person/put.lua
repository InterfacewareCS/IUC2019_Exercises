local database = require "utils.database"

-- API Call PUT /person

--[[ Update the person's information on the backend.]]

local function Person(Call, App)
   local Result = Call.response()

   local Success, QueryResult = pcall(
      database.executeSql, 
      [[UPDATE Patient SET]]..
      [[ name = ']]..Call.data.name..
      [[', telecom = ']]..Call.data.telecom..
      [[', gender = ']]..Call.data.gender..
      [[', birthDate = ']]..Call.data.birthDate..
      [[', address = ']]..Call.data.address..
      [[' WHERE identifier = ']]..Call.data.identifier..[[']]
   )

   if Success then 
      Result.data.Status = true
      Result.data.Description = "Success!"
   else
      Result.data.Status = false
      Result.data.Description = "Unexpected error!"
   end

   return Result
end

return Person