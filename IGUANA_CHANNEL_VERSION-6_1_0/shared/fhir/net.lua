-----------------------------------------------
--------------- HTTP requests -----------------
-----------------------------------------------
local Net = {}

-- Auth Headers:
-- Authorization: Bearer <token>

Net.doGet = function(Url, Format, header)
   trace(Url)
   trace(Format)
   local GetResult, GetCode, GetHeaders = net.http.get{
      url = Url, 
      parameters = {_format = Format},
      headers = {header},
      live = true
   }
   trace(GetResult, GetCode, GetHeaders)
   return GetResult, GetCode, GetHeaders
end

Net.doPut = function(Url, Data, header)
   local UpdateResult, UpdateCode, UpdateHeaders = net.http.put{
      url  = Url,
      data = Data,
      headers = {header},
      live = true
   }
   trace(UpdateResult, UpdateCode, UpdateHeaders)
   return UpdateResult, UpdateCode, UpdateHeaders
end

Net.doPost = function(Url, Body, Format, header)
  local PostResult, PostCode, PostHeaders = net.http.post{
      url  = Url,
      body = Body,
      parameters = {_format = Format},
      headers = {header},
      live = true
   }
   trace(PostResult, PostCode, PostHeaders)
   return PostResult, PostCode, PostHeaders
end

Net.doDelete = function(Url, header)
   local DeleteResult, DeleteCode, DeleteHeaders = net.http.delete{
      url=Url,
      headers = {header},
      live=true
   }
	trace(DeleteResult, DeleteCode, DeleteHeaders)
   return DeleteResult, DeleteCode, DeleteHeaders
end

return Net