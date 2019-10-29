-- _grammarHash API call
-- Servers up an MD5 hash of the grammar to the caller.
-- This is cached for efficiency.
-- It is used by the client to see if it has an up to date copy of the grammar

local function ReadFile(FileName)
	local F = io.open(FileName, "rb")
   local Content = F:read("*a");
   F:close()
   return Content
end

local Hash = ''

local GrammarHash = function(R,A)
   -- Cache the hash in memory
   if #Hash == 0 then
      local FileName = iguana.workingDir()..iguana.project.root()
      ..iguana.project.guid().."/"..A.grammar
      local Content = ReadFile(FileName)
      Hash = util.md5(Content)
   end
      
   return {Success=true, Hash=Hash}
end

return GrammarHash