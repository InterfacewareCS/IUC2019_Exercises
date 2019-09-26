-- Call GET /fhirserver
--[[ List the FHIR servers configured on the system.]]

function Fhirserver(Call, App)
   local Result = Call.response()
   
   -- TODO Write code to look at Call data and populate Result

   return Result
end

return Fhirserver