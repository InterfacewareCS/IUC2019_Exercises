-- ************************************************** --
-- FHIRprofiler
--  Creates a Profiler object in Lua that can be used
--  in the translator to generate FHIR JSON objects as
--  tables. It uses a base set of profiles, located in
--  the other/fhir/profiles/<version> folder. To ues a
--  set of profiles for a different version, create a
--  folder for it and put the resource and types JSON
--  files in there.
--
--  Base FHIR profiles should be published here:
--  https://www.hl7.org/fhir/downloads.html
--
--  If you would like to use custom profiles, they need
--  to be produced and stored in a similar fashion to
--  the standard base profiles provided by FHIR (i.e.
--  in a Bundle resource). The file locations of your
--  custom profiles then go in a list, and passed into
--  the FHIRprofiler function as the third argument.
--
--  Usage:
--   -- standard usage:
--   local FHIRprofiler = require 'fhir.profiler'
--   local Profiles = FHIRprofiler("4.0.0", "MyFhirDb")
--   local Patient = Profiles.Resources.Patient()
--   ...
--   -- with custom profiles:
--   local FHIRprofiler = require 'fhir.profiler'
--   local CustomProfiles = {}
--   table.insert(CustomProfiles, "/home/trevor/my_profiles/custom_resources.json")
--   local Profiles = FHIRprofiler("4.0.0", "MyFhirDb", CustomProfiles)
--   local Patient = Profiles.Resources.Patient()
--  
-- Trevor H.
-- ************************************************** --

local FHIRdb = require 'fhir.db'
local FHIRdbInitializer = require 'fhir.dbInitializer'
local FHIRresource = require 'fhir.resource'

local function getProfileFileList(FhirVersion, CustomProfiles)
   local List = CustomProfiles or {}
	table.insert(List, 1, os.fs.abspath(iguana.workingDir() .. iguana.project.root() .. "other/fhir/profiles/" .. FhirVersion .. "/resources.json"))
   table.insert(List, 1, os.fs.abspath(iguana.workingDir() .. iguana.project.root() .. "other/fhir/profiles/" .. FhirVersion .. "/types.json"))
   return List
end

local FHIRprofiler = function(FhirVersion, FhirDbName, CustomProfiles)
   local Profiler = {}
   
   -- initialize the FHIR DB with profiles and resources
   local ProfileFileList = getProfileFileList(FhirVersion, CustomProfiles)
   FHIRdbInitializer(ProfileFileList, FhirDbName)
   
   local DB = FHIRdb(FhirDbName)
   
   Profiler.Resources = {}
   local ResourceList = DB:listResourceNames('resource')
   
   for i=1,#ResourceList do
      Profiler.Resources[ResourceList[i]] = function()
         return FHIRresource(DB, ResourceList[i])
      end
   end
   
   Profiler.Types = {}
   local TypeList = DB:listResourceNames('complex-type')
   
   for i=1,#TypeList do
      Profiler.Types[TypeList[i]] = function()
         return FHIRresource(DB, TypeList[i])
      end
   end
   
   return Profiler
end

return FHIRprofiler
