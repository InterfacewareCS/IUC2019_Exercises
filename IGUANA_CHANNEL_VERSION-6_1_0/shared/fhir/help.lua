----------------------------------------------------------
----------- FHIR Client Help Dialog Utlities -------------
----------------------------------------------------------

local interactionHelp = {}

interactionHelp.storeReadHelp = function(ResourceName, InteractionFunction)
	local FunctionName = "fhirClient.resources." .. ResourceName .. ".read"
   local h = help.example()
   h.Title = FunctionName
   h.Desc = "Read a specific " .. ResourceName .. " resource entry from the FHIR server." 
   h.Usage = FunctionName .. "(<i>resourceId [,dataType]</i>)"
   h.Parameters = {
      [1]={['resourceId']={['Desc']='The id of the resource entry you want to read. <u>integer</u>'}},
      [2]={['dataType']={['Desc']='<i>optional: </i>Desired result data type (either json or xml, defaults to json) <u>string</u>'}}
   }
   h.Returns = {
      [1]={["Desc"]="The " .. ResourceName .. " resource entry for the requested id."},
      [2]={["Desc"]="The HTTP return code. <ul><li>200: Success</li><li>404: Could not find resource with that id.</li></ul>"},
      [3]={["Desc"]="The HTTP response headers."}
   }
   h.ParameterTable = false
   h.Examples = {[1]=[[<pre>
local ReadResult, ResultCode, ResponseHeaders = fhirClient.resources.]] .. ResourceName ..[[.read(10, "xml")</pre>]]}
   h.SeeAlso = ""
   
   help.set{input_function=InteractionFunction, help_data=h}
end


interactionHelp.storeSearchHelp = function(ResourceName, InteractionFunction)
	local FunctionName = "fhirClient.resources." .. ResourceName .. ".search"
   local h = help.example()
   h.Title = FunctionName
   h.Desc = "Search for all " .. ResourceName .. " resource entries on the FHIR server." 
   h.Usage = FunctionName .. "(<i>[dataType]</i>)"
   h.Parameters = {
      [1]={['dataType']={['Desc']='<i>optional: </i>Desired result data type (either json or xml, defaults to json) <u>string</u>'}}
   }
   h.Returns = {
      [1]={["Desc"]="The " .. ResourceName .. " resource bundle containing all found ".. ResourceName .. " resource entries."},
      [2]={["Desc"]="The HTTP return code.<ul><li>200: Success</li></ul>"},
      [3]={["Desc"]="The HTTP response headers."}
   }
   h.ParameterTable = false
   h.Examples = {[1]=[[<pre>
local SearchResultBundle, ResultCode, ResponseHeaders = fhirClient.resources.]] .. ResourceName ..[[.search()</pre>]]}
   h.SeeAlso = ""
   
   help.set{input_function=InteractionFunction, help_data=h}
end


interactionHelp.storeUpdateHelp = function(ResourceName, InteractionFunction)
	local FunctionName = "fhirClient.resources." .. ResourceName .. ".update"
   local h = help.example()
   h.Title = FunctionName
   h.Desc = "Update a specified " .. ResourceName .. " resource entry on the FHIR server."
   h.Usage = FunctionName .. "(<i>resourceId, data, [,dataType]</i>)"
   h.Parameters = {
      [1]={["resourceId"]={["Desc"]=[[The id of the ]] .. ResourceName .. [[ resource you want to update.<br>
                                     If a resource entry with that id doesn't exist it will be created.<u>integer</u>]]}},
      [2]={["data"]={["Desc"]="The resource string for the entry. (in the format specified by the dataType). <u>string</u>"}},
      [3]={["dataType"]={["Desc"]="<i>optional: </i>The input data type (either json or xml, defaults to json) <u>string</u>"}}
   }
   h.Returns = {
      [1]={["Desc"]="An operation outcome specifying the result of the update (or create if the entry didn't exist)."},
      [2]={["Desc"]="The HTTP return code.<ul><li>200: Success</li><li>400: Submitted data was not properly formatted/wrong dataType</ul>"},
      [3]={["Desc"]="The HTTP response headers."}
   }
   h.ParameterTable = false
   
   local UpdatedEntry = "updated" .. string.capitalize(ResourceName) .. "Entry"
   
   h.Examples = {[1]=[[<pre>
-- Make a read call to retrieve the resource entry with resourceId = 1 and parse the result.
local ]] .. ResourceName.. [[Entry = fhirClient.resources.]] .. ResourceName .. [[.read(1)
local ]] .. UpdatedEntry .. [[ = json.parse{data=]] .. ResourceName.. [[Entry}

-- Assuming this resource has an "active" key, update it to false. 
]] .. UpdatedEntry .. [[.active = false

local ]] .. UpdatedEntry .. [[String = json.serialize{data=]] .. UpdatedEntry .. [[}

-- Finally, update the resource entry on the server
local UpdateResult, ResultCode, ResponseHeaders = fhirClient.resources.]] .. ResourceName ..[[.update(1, ]].. UpdatedEntry ..[[String)</pre>]]}
   h.SeeAlso = ""
   
   help.set{input_function=InteractionFunction, help_data=h}
end


interactionHelp.storeCreateHelp = function(ResourceName, InteractionFunction)
	local FunctionName = "fhirClient.resources." .. ResourceName .. ".create"
   local h = help.example()
   h.Title = FunctionName
   h.Desc = "Create a new " .. ResourceName .. " resource entry on the FHIR server."
   h.Usage = FunctionName .. "(<i>resourceId, body, [,dataType]</i>)"
   h.Parameters = {
      [1]={["body"]={['Desc']="The resource string for the new entry. (in the format specified by the dataType). <u>string</u>"}},
      [2]={["dataType"]={['Desc']="<i>optional: </i>The input data type (either json or xml, defaults to json) <u>string</u>"}}
   }
   h.Returns = {
      [1]={["Desc"]="An operation outcome specifying the result of the creation."},
      [2]={["Desc"]="The HTTP return code.<ul><li>201: Successfully created</li><li>400: Submitted data was not properly formatted/wrong dataType</ul>"},
      [3]={["Desc"]="The HTTP response headers. (The 'Location' header will specify the location of the new resource)"}
   }
   h.ParameterTable = false
   
   local NewEntry = "new" .. string.capitalize(ResourceName) .. "Entry"
   
   h.Examples = {[1]=[[<pre>
-- Make a read call to retrieve the resource entry with resourceId = 1 and parse the result.
local ]] .. ResourceName.. [[Entry = fhirClient.resources.]] .. ResourceName .. [[.read(1)
local ]] .. NewEntry .. [[ = json.parse{data=]] .. ResourceName.. [[Entry}

-- Assuming this resource has an "active" key, change it to false. 
]] .. NewEntry .. [[.name = false

local ]] .. NewEntry .. [[String = json.serialize{data=]] .. NewEntry .. [[}

-- Finally, create a new resource entry on the server using the altered data from resource 1
local CreateResult, ResultCode, ResponseHeaders = fhirClient.resources.]] .. ResourceName ..[[.create(]].. NewEntry ..[[String)

-- The new entry location is in the Location header. 
-- Parse the url to get the new resourceId.
trace(ResponseHeaders.Location)
</pre>]]}
   h.SeeAlso = ""
   
   help.set{input_function=InteractionFunction, help_data=h}
end


interactionHelp.storeDeleteHelp = function(ResourceName, InteractionFunction)
	local FunctionName = "fhirClient.resources." .. ResourceName .. ".delete"
   local h = help.example()
   h.Title = FunctionName
   h.Desc = "Delete a specific " .. ResourceName .. " resource entry from the FHIR server." 
   h.Usage = FunctionName .. "(<i>resourceId</i>)"
   h.Parameters = {
      [1]={['resourceId']={['Desc']='The id of the resource entry you want to delete. <u>integer</u>'}}
   }
   h.Returns = {
      [1]={["Desc"]="If successful, will be an empty string."},
      [2]={["Desc"]="The HTTP return code. <ul><li>204: Successfully deleted, or never existed.</li></ul>"},
      [3]={["Desc"]="The HTTP response headers."}
   }
   h.ParameterTable = false
   h.Examples = {[1]=[[<pre>
local DeleteResult, ResultCode, ResponseHeaders = fhirClient.resources.]] .. ResourceName ..[[.delete(1)</pre>]]}
   h.SeeAlso = ""
   
   help.set{input_function=InteractionFunction, help_data=h}
end



local storeInteractionHelp = function(ResourceName, Interactions)
	for InteractionName, InteractionFunction in pairs(Interactions) do
	   -- Create the appropriate function name string
      local HelpStoreFuncName = "store" .. string.capitalize(InteractionName) .. "Help" 
      -- Call the function to store the help for the current interaction function.
      interactionHelp[HelpStoreFuncName](ResourceName, InteractionFunction)
   end
end

local storeResourceHelp = function(fhirClient)
   for ResourceName, Interactions in pairs(fhirClient.resources) do
      storeInteractionHelp(ResourceName, Interactions)
   end
end

local storeServerHelp = function(fhirClient)
	local h = help.example()
   h.Title = "fhirClient.serverUrl()"
   h.Desc = "Returns the base url of the FHIR server."
   h.Usage = "fhirClient.serverUrl()"
   h.Parameters = ""
   h.Returns = {
      [1]={["Desc"]="The base url of the FHIR server"}
   }
   h.ParameterTable = false
   h.Examples = {[1]=[[<pre>local ServerUrl = fhirClient.serverUrl()</pre>]]}
   h.SeeAlso = ""
   
   help.set{input_function=fhirClient.serverUrl, help_data=h}
end

local createClientHelpDialogs = function(fhirClient)
   storeServerHelp(fhirClient)
   storeResourceHelp(fhirClient)
end

interactionHelp.initialize = function(fhirClient)
   createClientHelpDialogs(fhirClient)
end


return interactionHelp