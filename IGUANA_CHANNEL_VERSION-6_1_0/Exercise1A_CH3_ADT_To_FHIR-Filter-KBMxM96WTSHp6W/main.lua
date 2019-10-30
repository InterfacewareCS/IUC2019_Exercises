-- The main function is the first function called from Iguana.
-- The Data argument will contain the message to be processed.
iguana.setTimeout(120)
local config = require ('config')
local FHIRprofiler = require 'fhir.profiler'
local Profiles = FHIRprofiler(config.FHIR_VERSION, config.FHIR_DB_NAME)
local handle = require 'handler'
local fHIrmap = require 'ADT_FHIR_PATIENT_MAP'
local JSONutilities = require 'fhir.resources.utilities.json'

function main(Data)
   -- 1. Parse incoming HL7 Message and verify its contents
   local Status, Orig, Name = pcall(handle.parsehl7, Data)
   if Status == false then 
      handle.errorHandle(Data)

   elseif Status == true then

      --2. create empty json of patient
      local patient = Profiles.Resources.Patient()

      --3. Map Inbound HL7 ADT Message To FHIR Patient Resource
      fHIrmap.map(Orig, patient)
      JSONutilities.removeEmptyNodes(patient)
      trace(patient)

      --4. Push data to queue 
      local DataOut = json.serialize{data=patient}
      trace(DataOut)
      queue.push{data=DataOut}
   end
end
