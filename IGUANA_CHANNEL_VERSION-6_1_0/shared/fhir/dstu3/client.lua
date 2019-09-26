local fhirClient = {}
fhirClient.resources = {}
fhirClient.isInitialized = false

local resourcesMT = {}

local Help = require "fhir.help"
local Net  = require "fhir.net"

-----------------------------------------------
----- FHIR Interaction Closure functions ------
-----------------------------------------------
local interactionClosures = {}

interactionClosures.readResourceClosure = function(Resource)
   local readResource = function(ResourceId, Format, headers)
      local Url = fhirClient.serverUrl() .."/".. Resource .. "/" .. ResourceId .. "/"
      return Net.doGet(Url, Format, headers)
   end
   return readResource
end

interactionClosures.searchResourceClosure = function(Resource)
   local searchResource = function(Format, searchString, headers)
      local Url = fhirClient.serverUrl().."/" .. Resource .. "?" .. searchString
      return Net.doGet(Url, Format, headers)
   end
   return searchResource
end

interactionClosures.searchDetailResourceClosure = function(Resource)
   local searchDetailResource = function(Format, searchString, headers) 
      local Url = fhirClient.serverUrl().."/" .. searchString -- searchString has both resource and Search parameters
      return Net.doGet(Url, Format, headers)
   end
   return searchDetailResource
end

interactionClosures.updateResourceClosure = function(Resource)
   local updateResource = function(ResourceId, Data, Format, headers)
      local FormatParameter = Format and "?_format=" .. Format or "" 
      local Url = fhirClient.serverUrl() .. Resource .. "/" .. ResourceId .. "/" .. FormatParameter

      return Net.doPut(Url, Data, headers)
   end
   return updateResource
end

interactionClosures.createResourceClosure = function(Resource)
   local createResource = function(Body, Format, headers)
      local Url = fhirClient.serverUrl().."/" .. Resource .. "/"
      return Net.doPost(Url, Body, Format, headers)
   end
   return createResource
end

interactionClosures.deleteResourceClosure = function(Resource)
   local deleteResource = function(ResourceId, headers)
      local Url = fhirClient.serverUrl().."/" .. Resource .. "/" .. ResourceId .. "/"
      trace(headers)
      return Net.doDelete(Url, headers)
   end
   return deleteResource
end

-----------------------------------------------
------------ FHIR Client Utilities ------------
-----------------------------------------------
local storeResourceInteractions = function(CurrentResource, parentTable)
   if CurrentResource.interaction == nil then
      -- Can't interact with this resource (Bundle, etc.)
      return
   end
   trace(CurrentResource.interaction)

   local CurrentInteraction = nil
   local ResourceName = CurrentResource.type
   -- Loop through each supported interaction for the resource, and store
   -- the appropriate function for that interaction in the resource's table.
   local resourceMT = {}
   for i= 1, #CurrentResource.interaction do
      CurrentInteraction = CurrentResource.interaction[i].code
      trace(CurrentInteraction)
      if CurrentInteraction == "search-type" then
         -- Special case (interaction name isn't in ideal form)
         resourceMT["search"] = interactionClosures.searchResourceClosure(ResourceName)
      elseif CurrentInteraction == "vread" then
         -- TODO
      elseif CurrentInteraction == "history-instance" then
         -- TODO
      elseif CurrentInteraction == "history-type" then
         -- TODO
      elseif CurrentInteraction == "patch" then
         -- TODO
      else
         -- General case, interaction name is in ideal form
         local ClosureFuncName = CurrentInteraction .. "ResourceClosure" 
         trace(ClosureFuncName)
         trace(ResourceName)
         trace(CurrentInteraction)
         trace(fhirClient)
         trace(interactionClosures)
         resourceMT[CurrentInteraction] = interactionClosures[ClosureFuncName](ResourceName)
         --fhirClient.resources[ResourceName][CurrentInteraction] = interactionClosures[ClosureFuncName](ResourceName)
      end
   end
   setmetatable(parentTable, {__index=resourceMT})
end

local createClientApi = function(ConformanceStatement)
   -- Loop through each supported resource, record it in the client object.
   -- Call to store each supported interaction within each one of those resource objects.
   local conformanceMT = {}
   for Index, CurrentResource in ipairs(ConformanceStatement.rest[1].resource) do
      local ResourceName = CurrentResource.type
      conformanceMT[ResourceName] = {}
      storeResourceInteractions(CurrentResource, conformanceMT[ResourceName])
   end
   setmetatable(fhirClient.resources,{__index=conformanceMT})
end

local getConformanceResource = function()
   -- Call the FHIR server to request the conformance statement
   local ConformanceStatement = Net.doGet(fhirClient.serverUrl() .. "/metadata")
   trace(ConformanceStatement)
   --iguana.logInfo(ConformanceStatement)
   return ConformanceStatement
end

local serverUrlClosure = function(ServerUrl)
   local getServerUrl = function()
      return ServerUrl
   end
   return getServerUrl
end


fhirClient.initialize = function(ServerUrl)
   fhirClient.serverUrl = serverUrlClosure(ServerUrl)
   -- Retrieve and parse the conformance statement from the server.
   local ConformanceStatement = json.parse{data= getConformanceResource() }
   -- Create a helper client API based on the supported resources/interactions within the conformance statement.
   createClientApi(ConformanceStatement)
   Help.initialize(fhirClient)
   fhirClient.isInitialized = true
end

-- fhirClient.initialize() --
-- Need this here so it gets initialized right when file is required -- 
local h = help.example()
h.Title = "fhirClient.initialize"
h.Desc = "Initializes the FHIR client module."
h.Usage = "fhirClient.initialize(<i>serverUrl</i>)"
h.Parameters = {
   [1]={['serverUrl']={['Desc']='Base url for FHIR server. <u>string</u>'}}
}
h.Returns = ""
h.ParameterTable = false
h.Examples = {[1]=[[<pre>local ServerUrl = "http://192.168.0.1:6544/fhir/"<br>fhirClient.initialize(ServerUrl)</pre>]]}
h.SeeAlso = ""
help.set{input_function=fhirClient.initialize, help_data=h}


return fhirClient