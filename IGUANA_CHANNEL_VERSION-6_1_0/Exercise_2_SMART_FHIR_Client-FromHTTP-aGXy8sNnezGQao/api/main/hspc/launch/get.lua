-- API Call GET /hspc/launch

--[[ Provide redirect URL for the HSPC app "Launch" function.]]

local data = require 'database_driver'

local function Hspc(Call, App)
   local Result = Call.response()
	
   local IssuerUrl = Call.params.iss
   local LaunchId = Call.params.launch
   
   -- Retrieve /metadata from the Issuing HSPC Application
   App.FhirClient.initialize(IssuerUrl)
   local Security = {}
   local CapabilityStatement = App.FhirClient.capabilityStatement
	
   for i=1,#CapabilityStatement.rest[1].security.extension[1].extension do
      local Item = CapabilityStatement.rest[1].security.extension[1].extension[i]
      Security[Item.url] = Item.valueUri
   end

   -- set up the search parameters:
   data.clearSearchParamTable()
	local Resources = CapabilityStatement.rest[1].resource
   for i=1,#Resources do
      local ResourceName = Resources[i].type
      local SearchParams = json.serialize{data=Resources[i].searchParam,compact=true}
      data.insertSearchParam(ResourceName, SearchParams)
   end
	
   local Client = data.GetClient()
   local ClientId = Client.ClientId
   local ClientUrl = Client.ClientUrl
   if not ClientId then
      return Result
   end
	
	local StateGuid = util.guid(128)
   data.InitClientAccessEntry(StateGuid, LaunchId, Security.token)
	
   local Location = Security.authorize .. 
      "?client_id=" .. ClientId .. 
      "&response_type=code" ..
      "&aud=" .. filter.uri.enc(IssuerUrl) ..
      "&launch=" .. LaunchId ..
      "&redirect_uri=" .. filter.uri.enc(ClientUrl .. "hspc/redirect") ..
	   "&state=" .. StateGuid
   data.InsertLaunchServerAccessToken(LaunchId)
   net.http.respond{body="Hello, I'm Iggy, I'm redirecting you.",code=307,headers={Location=Location}}
   Result.has_responded = true
   
   return Result
end

return Hspc