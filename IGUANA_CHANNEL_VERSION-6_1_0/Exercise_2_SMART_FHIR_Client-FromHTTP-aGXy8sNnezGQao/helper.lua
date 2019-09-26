local m = {}
function m.toJson (tableJ)
   local result

   for key, value in pairs(tableJ) do

      -- prepare json key-value pairs and save them in separate table
      table.insert(result, string.format("\"%s\":%s", key, value))
   end

   -- get simple json string
   result = "{" .. table.concat(result, ",") .. "}"
   return result
end

function m.formatToken (token)
   local result = "Authorization: Bearer " .. token
   return result
end

function m.formatURL (data)
   local base = data.SearchBase .. [[?]]
   local fBase
   for i=1,#data.Parameters do
      base = base .. data.Parameters[i].name .. [[=]] .. data.Parameters[i].value .. [[&]]
   end
   if base:sub(base:len()) == "&" then 
      fBase = base:sub(1, base:len()-1)
   end
   
   return fBase
end
   
return m