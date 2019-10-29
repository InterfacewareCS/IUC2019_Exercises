-- Iguana API Project

-- For profiling it's helpful to collect when we start reading main
local InitStart = os.clock()

local ServerCreate = require 'apiframework.v1.lua.server'

-- Information that you want all the API calls to access 
-- can go on this object.
local App = {Name="MyApp"}

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
---ServerConfig.test = <your user ID>

-- Record when we execute this line - loading of the project is done.
local InitEnd = os.clock()

function main(Data)  
   local MainStart = os.clock()
   local Server = ServerCreate(ServerConfig)
   Server:serveRequest{data=Data}
   local MainEnd = os.clock()
   trace("Loading Time: ",InitEnd-InitStart)
   trace("Call Time   :", MainEnd-MainStart)
end
