local azure = {}
local retry = require 'retry'
local configs = require 'azure.configurations'

-- local functions
local char_to_hex = function(c)
  return string.format("%%%02X", string.byte(c))
end

local function urlencode(url)
  if url == nil then
    return
  end
  url = url:gsub("\n", "\r\n")
  url = url:gsub("([^%w. ])", char_to_hex)
  url = url:gsub(" ", "+")
  return url
end

local function WebServiceError(Success, ErrMsgOrReturnCode, Code, Headers)
   local funcSuccess
   if Success then
      -- successfully call the web service
      funcSuccess = true -- don't retry
      -- we still need to check the Code (HTTP return code)
      if Code == 503 then
         iguana.logInfo('WebService connection: 503 - Service Unavailable: unavailable probably temporarily overloaded')
         -- wait longer before retrying (in this case an extra 30 seconds)
         -- this is an example and can be customized to your requirements
         -- NOTE: Some WebServices may include a retry-after field in the Headers
         --       if so you can use this to customize the delay (sleep) period
         if not iguana.isTest() then
            util.sleep(30000)
         end
         funcSuccess = false -- retry
      elseif Code == 404 then
         iguana.logInfo('WebService connection: 404 - Not Found: the resource was not found but may be available in the future')
         -- wait longer before retrying (in this case an extra 120 seconds)
         -- this is an example and can be customized to your requirements
         -- NOTE: Some WebServices may include a retry-after field in the Headers
         --       if so you can use this to customize the delay (sleep) period
         if not iguana.isTest() then
            util.sleep(120000)
         end
      elseif Code == 408 then
         iguana.logInfo('WebService connection: 408 - Request Timeout: the server timed out probably temporarily overloaded')
         -- wait longer before retrying (in this case an extra 30 seconds)
         -- this is an example and can be customized to your requirements
         -- NOTE: Some WebServices may include a retry-after field in the Headers
         --       if so you can use this to customize the delay (sleep) period
         if not iguana.isTest() then
            util.sleep(30000)
         end
      elseif Code == 429 then
         iguana.logInfo('WebService connection: 429 - Too Many Requests: too many requests or concurrent connections')         
         -- wait longer before retrying (in this case an extra 60 seconds)
         -- this is an example and can be customized to your requirements
         -- NOTE: Some WebServices may include a retry-after field in the Headers
         --       if so you can use this to customize the delay (sleep) period
         if not iguana.isTest() then
            util.sleep(60000)
         end
         funcSuccess = false -- retry
      elseif Code == 401 then
         iguana.logError('WebService connection: 401 - Unauthorized: usually indicates Login failure')
         -- you could/should also email the administrator here
         -- https://help.interfaceware.com/code/details/send-an-email-from-lua?v=6.0.0
         
         -- in this case we don't want to retry 
         -- so we don't set funcSuccess = false
      elseif Code == 403 then
         iguana.logError('WebService connection: 403 - Forbidden: you do not have permission to access this resource')
         -- you could/should also email the administrator here
         -- https://help.interfaceware.com/code/details/send-an-email-from-lua?v=6.0.0
         
         -- in this case we don't want to retry 
         -- so we don't set funcSuccess = false
      elseif Code == 413 then
         iguana.logError('WebService connection: 413 - Payload Too Large: the requested result is too large to process')
         -- you could/should also email the administrator here
         -- https://help.interfaceware.com/code/details/send-an-email-from-lua?v=6.0.0
         
         -- in this case we don't want to retry 
         -- so we don't set funcSuccess = false
      end
   else
      -- anything else should be a genuine error that we don't want to retry
      -- you can customize the logic here to retry specific errors if needed
      iguana.logError('WebService connection: ERROR '..tostring(Code)..' - '..tostring(ErrMsgOrReturnCode))
      funcSuccess = true -- we don't want to retry
   end
   return funcSuccess
end

function apiCall(tokenEndpoint, body, headers)   
   local r, e, h = net.http.post{url=tokenEndpoint, body=body, headers=headers, live=configs.ISLIVE}
   return r, e, h
end

-- punlic function
function azure.getAccessTokenV1Data()
   -- create api body
   local bodyTb = {
      "client_id=", urlencode(configs.CLIENT_ID), "&",
      "client_secret=", urlencode(configs.CLIENT_SECRET), "&",
      "grant_type=", "client_credentials", "&",
      "resource=", urlencode(RESOURCE) 
   }
   local body = table.concat(bodyTb)
   local len = body:len()
   
    -- Create api headers
   local headers = {}
   headers["Content-Type"]='application/x-www-form-urlencoded'
   headers["accept-encoding"]='gzip, deflate'
   headers["content-length"]=len
   headers["Connection"]='keep-alive'
   
   -- Call API
   local r, e, h, re = retry.call{func=apiCall, arg1=configs.TOKEN_ENDPOINT_V1, arg2=body, arg3=headers, retry=configs.RETRY, pause=configs.RETRYPAUSE, funcname='apiCall', errorfunc=WebServiceError}
   if tonumber(e) == 200 then
      return json.parse(r)
   else
      return false
   end
end

function azure.getAccessTokenV2Data()
   -- create api body
   local bodyTb = {
      "client_id=", urlencode(configs.CLIENT_ID), "&",
      "client_secret=", urlencode(configs.CLIENT_SECRET), "&",
      "grant_type=", "client_credentials", "&",
      "scope=", urlencode(configs.RESOURCE..'/.default')   
   }
   local body = table.concat(bodyTb)
   local len = body:len()
   
    -- Create api headers
   local headers = {}
   headers["Content-Type"]='application/x-www-form-urlencoded'
   headers["accept-encoding"]='gzip, deflate'
   headers["content-length"]=len
   headers["Connection"]='keep-alive'
   
   -- Call API
   local r, e, h, re = retry.call{func=apiCall, arg1=configs.TOKEN_ENDPOINT_V2, arg2=body, arg3=headers, retry=configs.RETRY, pause=configs.RETRYPAUSE, funcname='apiCall', errorfunc=WebServiceError}
   if tonumber(e) == 200 then
      return json.parse(r)
   else
      return false
   end
end

local AccessTokenV1DataHelp=[[{
"Returns": [{"Desc": "The access token JSON data or false for error"}],
"Title": "azure.getAccessTokenV1Data",
"Usage": "azure.getAccessTokenV1Data()",
"Examples": [
"local tokenData = azure.getAccessTokenV1Data()<br/>
   if tokenData ~= false then<br/>
      local token  = tokenData.access_token<br/>
      trace(token)<br/>
   end"
],
"Desc": "This function retrieve Azure Active Directory access token using OAuth2 Azure Active Directory (v1.0) endpoints."
}]]

help.set{input_function=azure.getAccessTokenV1Data, help_data=json.parse{data=AccessTokenV1DataHelp}}

local AccessTokenV2DataHelp=[[{
"Returns": [{"Desc": "The access token JSON data or false for error"}],
"Title": "azure.getAccessTokenV2Data",
"Usage": "azure.getAccessTokenV2Data()",
"Examples": [
"local tokenData = azure.getAccessTokenV2Data()<br/>
   if tokenData ~= false then<br/>
      local token  = tokenData.access_token<br/>
      trace(token)<br/>
   end"
],
"Desc": "This function retrieve Azure Active Directory access token using OAuth2 Microsoft identity platform (v2.0) endpoints."
}]]

help.set{input_function=azure.getAccessTokenV2Data, help_data=json.parse{data=AccessTokenV2DataHelp}}

return azure