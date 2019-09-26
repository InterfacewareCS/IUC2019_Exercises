-- ************************************************** --
-- FILEio
--  Perform File I/O
--
-- Trevor
-- ************************************************** --

local Live = false

local FILEio = function()
   local IO = {}
	
   local methods = {}
   setmetatable(IO,{__index=methods})
   
   function methods:readAll(Location, Format, Mode)
      local FileHandle = io.open(Location, Mode)
      local Content = FileHandle:read("*a")
      FileHandle:close()
      return Content
   end
   
   function methods:writeAll(Location, Content)
      local FileHandle = io.open(Location, 'w+')
      FileHandle:write(Content)
      FileHandle:close()
   end
   
   return IO
end

return FILEio