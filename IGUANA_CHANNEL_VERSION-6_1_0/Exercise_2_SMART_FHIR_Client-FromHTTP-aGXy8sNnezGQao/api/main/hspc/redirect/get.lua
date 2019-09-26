-- Call GET /hspc/redirect
--[[ Provide a redirect landing]]

local data = require 'database_driver'

function Hspc(Call, App)
   local Result = Call.response()
   
   
   local Code = Call.params.code
   local StateGuid = Call.params.state
   
   data.updateClientAccessCode(StateGuid, Code)
   
   local ClientAccess = data.GetClientAccess("StateGuid", StateGuid)
   
   local Params = {}
   Params.code=ClientAccess[1].Code
   Params.grant_type="authorization_code"
   Params.redirect_uri = data.GetClient().ClientUrl .. "hspc/redirect"
   Params.client_id = data.GetClient().ClientId
   trace(Params, json.serialize{data=Params})
   
   local Headers = {}
   Headers["Accept"] = "application/json;"
   Headers["Content-Type"] = "application/x-www-form-urlencoded;"
   
	local R,C,H = net.http.post{url=ClientAccess[1].TokenEndpoint, parameters=Params, headers=Headers, live=true}
   --parse json and insert to db
   iguana.logInfo(R)
   local Rjson = json.parse{data=R}
   local launch = data.GetLaunch("StateGuid", StateGuid)
	data.InsertNewServerAccessToken(Rjson, launch[1].LaunchId)
	
   
   -- TODO
   --  make use of the access token returned by storing it in a new table
   local Location = "http://localhost:6544/fhir-app/"
	net.http.respond{body=[[Please continue on to <a href="]] .. data.GetClient().ClientUrl .. [[">fhir-app</a>.]],code=307,headers={Location=Location}}
   Result.has_responded = true
	
   return Result
end

return Hspc