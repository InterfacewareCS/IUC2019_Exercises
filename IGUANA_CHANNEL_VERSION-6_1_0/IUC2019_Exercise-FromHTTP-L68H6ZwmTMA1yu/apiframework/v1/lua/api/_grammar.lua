-- _grammar
-- This call will return the Grammar in JSON format to the caller for this API.
-- This can be used by the client to get the grammar.

local function ReadFile(FileName)
   local F = io.open(FileName, "rb")
   local Content = F:read("*a")
   F:close()
   return Content
end

local function LoadGrammar(R, A)  
   local FileName = iguana.workingDir()..iguana.project.root()
       ..iguana.project.guid().."/"..A.grammar
   local Content = ReadFile(FileName)
   local Grammar = json.parse{data=Content}
   return {Success=true, Grammar=Grammar}
end

return LoadGrammar