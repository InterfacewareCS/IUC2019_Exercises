local database = require 'utils.database'

-- The main function is the first function called from Iguana.
-- The Data argument will contain the message to be processed.
function main(Data)

   ------------------------------------------------------------------------   
   -- Exercise 1 ----------------------------------------------------------
   -- Extract JSON data to build SQL command ------------------------------
   ------------------------------------------------------------------------

   local Values = json.parse{data=Data}

   local sqlTable = {
      Values.identifier, 
      Values.name, 
      Values.telecom, 
      Values.gender,
      Values.birthDate,
      Values.address     
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
      VALUES (']]..table.concat(sqlTable, "', '")..[[')]]
   )

   ------------------------------------------------------------------------   
   -- Exercise 3 ----------------------------------------------------------
   -- Create responses ----------------------------------------------------
   ------------------------------------------------------------------------   

   if Success then 
      iguana.logInfo('Success!')
   elseif QueryResult.code == 19 then
      -- Handle case where person already exists on database
      iguana.logWarning('Person identifier already exists in database!')
   else
      iguana.logError('Unexpected error!')
   end 

end