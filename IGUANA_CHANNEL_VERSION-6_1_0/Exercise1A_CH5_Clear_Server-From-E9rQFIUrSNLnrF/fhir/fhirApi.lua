local hFunctions = require ('helper')

local this = {}

function this.deleteAllResources (fhirClient, token)
   local resources = this.returnAllResources(fhirClient, token)
   if resources == nil then 
      iguana.logInfo('All resources deleted. FHIR server cleared successfully.')
      process = false
      return
   end
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
   if entry.entry == nil then 
      return
   end
   local resourceID = {}
   local i = 1
   for k, v in pairs (entry.entry) do
      resourceID[i] = v.resource.id
      i = i + 1
   end
   return resourceID
end

return this 

