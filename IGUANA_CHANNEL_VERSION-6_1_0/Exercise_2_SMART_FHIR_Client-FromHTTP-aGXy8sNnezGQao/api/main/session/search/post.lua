-- Call POST /session/search
--[[ Supply a search query with parameters. Returns FHIR Resource if found]]
local datab = require 'database_driver'
local hFunction = require 'helper'
function Session(Call, App)
   local Result = Call.response()
   
   --Initialize server
   if iguana.isTest() == true then 
      local ServerUrlList = {"https://api-v8-r4.hspconsortium.org/HSPC1/open",
         "https://api-v8-r4.hspconsortium.org/HSPC1/data", 
         "https://api-v8-r4.hspconsortium.org/DaVinciCDexProvider/open"
      }
      local ServerUrl = ServerUrlList[1]
      App.FhirClient.initialize(ServerUrl)
   end
   --Parse Parameters
   local url = hFunction.formatURL(Call.data)

   Result.data.fResource = App.FhirClient.resources[Call.data.SearchBase].searchDetail("json",url, headers)
   
   
   
   return Result
end

return Session