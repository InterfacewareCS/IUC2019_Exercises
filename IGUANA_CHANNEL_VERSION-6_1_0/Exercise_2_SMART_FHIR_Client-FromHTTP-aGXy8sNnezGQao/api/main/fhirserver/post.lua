-- Call POST /fhirserver
--[[ Create or update a new FHIR Server resource in the DB.]]

function Fhirserver(Call, App)
   local Result = Call.response()
   
   -- TODO Write code to look at Call data and populate Result

   return Result
end

return Fhirserver