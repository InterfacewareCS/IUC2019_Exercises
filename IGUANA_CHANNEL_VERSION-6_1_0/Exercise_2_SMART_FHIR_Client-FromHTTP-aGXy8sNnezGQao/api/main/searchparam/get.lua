-- Call GET /searchparam
--[[ ]]
local data = require 'database_driver'

function Searchparam(Call, App)
   local Result = Call.response()
   
   Result.data = data.getSearchParams(Call.params.resource_name)
   
   return Result
end

return Searchparam