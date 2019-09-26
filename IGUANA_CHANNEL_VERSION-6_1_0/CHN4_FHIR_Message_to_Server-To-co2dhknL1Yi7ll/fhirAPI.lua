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

function this.searchResource (fhirClient, token, id)
   local PostResult, PostCode, PostHeaders = fhirClient.resources.Patient.search("json",'_id='..id, token)
   return PostCode, PostResult
end

function this.deleteResource (fhirClient, token, id)
   local DeleteResult, DeleteCode, DeleteHeaders = fhirClient.resources.Patient.delete(id, token)
   trace(DeleteCode)
   return DeleteCode, DeleteResult
end

function this.deleteAllResources (fhirClient, token)
   local resources = this.returnAllResources(fhirClient, token)
   local x = 0
   for i = 1, #resources do
      local DeleteResult, DeleteCode, DeleteHeaders = fhirClient.resources.Patient.delete(resources[i], token)
      trace(DeleteCode)
      trace(DeleteResult)
      if DeleteCode ~= 401 then 
         x = x + 1
      end
   end
   return x ..' / '.. #resources .. ' Resources Deleted' 
end

function this.returnAllResources (fhirClient, token)
   local PostResult, PostCode, PostHeaders = fhirClient.resources.Patient.search("json",'_id=', token)
   local entry = json.parse{data=PostResult}
   local resourceID = {}
   local i = 1
   for k, v in pairs (entry.entry) do
      resourceID[i] = v.resource.id
      i = i + 1
   end
   return resourceID
end

return this 

