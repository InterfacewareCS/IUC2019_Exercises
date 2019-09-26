--This is a POC script that will take an incoming HL7 Message, Parse it, and upload it to a FHIR Server.
local fhirClient   = require "fhir.dstu3.client"
local hFunctions = require ('helper')
local fapi = require 'fhir.fhirAPI'
local azure = require 'azure.adTokenAPI'
local config = require 'azure.configurations'
local m_Db = db.connect{api=db.SQLITE, name='token.db'}
RESOURCE = hFunctions.AZURE_FHIR_URL()
process = true
function main()
   if process then

      -- 1. Initialize Server
      local ServerUrl = RESOURCE
      fhirClient.initialize(ServerUrl)

      -- 2. Retreive token
      local token = hFunctions.generateToken(m_Db)

      -- B. Delete All Patients in FHIR Server
      Status, Code, Result = pcall(fapi.deleteAllResources, fhirClient, token)
      trace(Status, Code, Result)
   end
end