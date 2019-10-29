local database = require "utils.database"

-- Call GET /people
--[[ Get a group of people from the database]]

function People(Call, App)
   local Result = Call.response()
   
   local QueryResult = database.executeSql([[SELECT * FROM Patient LIMIT ]]..Call.params.Limit)
   
   for i=1, #QueryResult do 
      Result.data.People[i].address = QueryResult[i].address:nodeValue()
      Result.data.People[i].birthDate = QueryResult[i].birthDate:nodeValue()
      Result.data.People[i].gender = QueryResult[i].gender:nodeValue()
      Result.data.People[i].identifier = QueryResult[i].identifier:nodeValue()
      Result.data.People[i].name = QueryResult[i].name:nodeValue()
      Result.data.People[i].telecom = QueryResult[i].telecom:nodeValue()      
   end

   return Result
end

return People