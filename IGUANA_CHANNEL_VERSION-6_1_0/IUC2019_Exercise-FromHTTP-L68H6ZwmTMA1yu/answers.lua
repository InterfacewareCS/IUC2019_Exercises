local database = require "utils.database"

-- API Call POST /person

--[[ Create a new person in the database.]]

local function Person(Call, App)
   local Result = Call.response()

   ------------------------------------------------------------------------   
   -- Exercise 1 ----------------------------------------------------------
   -- Extract HTTP request data to build SQL command ----------------------
   ------------------------------------------------------------------------
   
   local Values = {
      Call.data.identifier, 
      Call.data.name, 
      Call.data.telecom, 
      Call.data.gender, 
      Call.data.birthDate, 
      Call.data.address
   }
   
   ------------------------------------------------------------------------   
   -- Exercise 2 ----------------------------------------------------------
   -- Build SQL command ---------------------------------------------------
   ------------------------------------------------------------------------
   
   local Success, QueryResult = pcall(
      database.executeSql, 
      [[INSERT INTO Patient (
      identifier, 
      name, 
      telecom, 
      gender, 
      birthDate, 
      address) 
      VALUES (']]..table.concat(Values, "', '")..[[')]]
   )

   ------------------------------------------------------------------------   
   -- Exercise 3 ----------------------------------------------------------
   -- Create HTTP response ------------------------------------------------
   ------------------------------------------------------------------------   
   
   if Success then 
      Result.data.Status = true
      Result.data.Description = "Success!"
   elseif QueryResult.code == 19 then
      -- Handle case where person already exists on database
      Result.data.Status = false
      Result.data.Description = "Person identifier already exists in database!"
   else
      Result.data.Status = false
      Result.data.Description = "Unexpected error!"
   end 

   return Result
end

return Person