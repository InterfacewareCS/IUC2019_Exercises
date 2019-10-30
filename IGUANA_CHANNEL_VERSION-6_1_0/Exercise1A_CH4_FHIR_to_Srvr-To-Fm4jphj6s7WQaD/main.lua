--This is a POC script that will take an incoming HL7 Message, Parse it, and upload it to a FHIR Server.
local fhirClient   = require "fhir.dstu3.client"
local hFunctions = require ('helper')
local fapi = require 'fhir.fhirAPI'
local azure = require 'azure.adTokenAPI'
local config = require 'azure.configurations'
local m_Db = db.connect{api=db.SQLITE, name='token.db'}
RESOURCE = hFunctions.AZURE_FHIR_URL()
function main(Data)

   -- 1. Initialize Server
   local ServerUrl = RESOURCE
   fhirClient.initialize(ServerUrl)

   -- 2. Retreive token
   local token = hFunctions.generateToken(m_Db)

   -- 3. Post to Server
   Status, Code, Result = pcall(fapi.postResource, token, Data, fhirClient)
   -- A response code of 201 means the resource was successfully created.
   trace(Status, Code, Result)
   json.parse{data=Result}
   if Status then 
      iguana.logInfo('Uploaded Fhir Resource with response code: ' .. Code .. '\n\n' .. Result)
   else
      iguana.logInfo('Error: ' .. Code .. '\n\n' .. Result)
   end
end
