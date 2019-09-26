local hFunctions = require ('helper')

local this = {}

function this.postResource (token, Data, fhirClient)
   -- 1. Create Content type
   local cont = {'Content-Type: application/fhir+json',token}
   local fit = json.serialize{data=cont}

   -- 2. Post to FHIR Server
   local PostResult, PostCode, PostHeaders = fhirClient.resources.Patient.create(Data, nil, cont)
   return PostCode, PostResult
end

return this 

