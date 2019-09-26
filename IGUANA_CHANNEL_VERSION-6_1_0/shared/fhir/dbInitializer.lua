-- ************************************************** --
-- FHIRdbInitializer
--  Initialize the DB used in FHIRdb.
--  This should only be used once, to parse the profile
--  JSON files and store them into the DB.
--
-- Trevor
-- ************************************************** --

local FILEio = require 'FILE.FILEio'
local FHIRdb = require 'fhir.db'

local FHIRdbInitializer = function(ProfileFileList, FhirDbName)
   local DB = FHIRdb(FhirDbName)
   if DB:isInitialized() then -- sql script error the first time. state Table not existing yet
      return
   end

   DB:dropTables()
   local ProfileContent, ProfileJson
   for i=1,#ProfileFileList do
      ProfileContent = FILEio():readAll(ProfileFileList[i])
      ProfileJson = json.parse{data=ProfileContent}
      DB:init(ProfileJson)
   end
   DB:setIsInitialized(true)
   
end

return FHIRdbInitializer