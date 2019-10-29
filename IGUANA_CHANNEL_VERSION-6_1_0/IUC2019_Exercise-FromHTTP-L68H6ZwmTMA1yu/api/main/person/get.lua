local database = require "utils.database"

-- API Call GET /person

--[[ Returns a person's information based on their ID number.]]

local function Person(Call, App)
   local Result = Call.response()

   local QueryResult = database.executeSql(
      [[SELECT * FROM Patient WHERE identifier=']]..Call.params.identifier..[[']]
   )

   if #QueryResult == 1 then
      Result.data.address = QueryResult[1].address:nodeValue()
      Result.data.birthDate = QueryResult[1].birthDate:nodeValue()
      Result.data.gender = QueryResult[1].gender:nodeValue()
      Result.data.identifier = QueryResult[1].identifier:nodeValue()
      Result.data.name = QueryResult[1].name:nodeValue()
      Result.data.telecom = QueryResult[1].telecom:nodeValue()
   end

   return Result
end

return Person