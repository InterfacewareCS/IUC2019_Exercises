-- Call POST /session/start
--[[ Use this API to start a session for a resource ID.]]
local fhirClient   = require "fhir.r4.client"
local datab = require "database_driver"
local util = require "helper"
function Session(Call, App)
   --1. Declare Variables
   local Result = Call.response()
   local patient = Call.data.patient

   --1.5 Establish FHIR server
   local ServerUrlList = {"https://api-v8-r4.hspconsortium.org/HSPC1/open",
      "https://api-v8-r4.hspconsortium.org/HSPC1/data"
   }

   local ServerUrl = ServerUrlList[1]

   -- TODO Write code to look at Call data and populate Result
   --2. Pull token from db via patient and format for request
   local token = datab.GetServerAccessToken('patient', patient)
   
   -- Disregarding OAuth workflow for connectathon
   --local tokenH = util.formatToken(token[1].access_token)

   --3. Get patient resource from server via patient 
   App.FhirClient.initialize(ServerUrl)
   local response = App.FhirClient.resources.Patient.read(patient,"json", tokenH)

   --4. Return resource to result
   Result.data.patient = response
   return Result
end

return Session