-- _loadTemplates
-- This call is used by the GUI.  It iterates through the project and finds every file with an html
-- extension in the apiframework/v1/web/ directory and collects it into a JSON reply.
-- This is used by the Javascript code to create a collection of HTML templates which are used with
-- the Mustache templating system that the GUI of this API uses.

local function LoadFile(File)
   local F = io.open(File, "rb")
   local C = F:read("*a")
   F:close()
   return C
end

local function HtmlFiles(FileList, TestUser)
   local List = {}
   local ProjectRoot
   if TestUser then
      ProjectRoot = iguana.workingDir()..'edit/'..TestUser.."/"..iguana.project.guid()..'/'
   else
      ProjectRoot = iguana.workingDir()..iguana.project.root()..iguana.project.guid()..'/'
   end
   
   for File in pairs(FileList) do
      if File:sub(-4) == "html" then
         -- Only include files in the root.
         if File:sub(1, 20) == 'apiframework/v1/web/' then
            List[File:sub(20)] = LoadFile(ProjectRoot..File)    
         end     
      end
   end
   return List
end

local function LoadTemplate(R, Server)
   local Template = {}
   local FileList = iguana.project.files()
   local Collection = HtmlFiles(FileList, Server.test)
   return Collection
end

return LoadTemplate