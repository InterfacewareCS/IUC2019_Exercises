-- Iguana API Project

-- For profiling it's helpful to collect when we start reading main
local InitStart = os.clock()

local ServerCreate = require 'apiframework.v1.lua.server'
local fhirClient = require 'fhir.r4.client'
-- Information that you want all the API calls to access 
-- can go on this object.
local App = {
   Name = "MyApp",
   FhirClient = fhirClient
}

local ServerConfig = {
   app     =  App,
   folder  = 'main',
   grammar = 'grammar.json',
   mode    = 'debug' -- {debug, normal} : debug will pass internal error details out to client
}

-- By default the API framework will serve up *milestoned* javascript, CSS and HTML templates
-- from apiframewor/v1/web/ 
-- If you are doing work to change these templates then it's useful to set ServerConfig to your
-- user ID.  Then the framework will just serve up these files from your development sandbox which is
-- convenient for changing these files.
--ServerConfig.test = 'trevor'
local bd = require "database_driver"
local parseCSV= require 'csv'
-- Record when we execute this line - loading of the project is done.
local InitEnd = os.clock()

function main(Data)  
   --fillTable(Data)
   local MainStart = os.clock()
   local Server = ServerCreate(ServerConfig)
   Server:serveRequest{data=Data}
   local MainEnd = os.clock()
   trace("Loading Time: ",InitEnd-InitStart)
   trace("Call Time   :", MainEnd-MainStart)
end

function fillTable(Data)

   -- Parse CSV file
   local mappings = parseCSV(Data)
   table.remove(mappings, 1)
   trace(mappings)

   -- Create DB table
   local dbTable = dbs.init{filename = 'mappings.dbs'}
   local M = dbTable:tables()

   -- Map into table
   for i=1, #mappings do
      M.Loinc[i].ClinicalNoteType = mappings[i][1]
      M.Loinc[i].GeneralCode = mappings[i][2]
      M.Loinc[i].ValueSetName = mappings[i][3]
      M.Loinc[i].Reference = mappings[i][4]
   end

   -- Merge 
   bd:Connection()
   bd.Connection():merge{data=M, live = false}
end