-- _login 
-- This call is used to login and create a session for the GUI
-- which is used to distribute administration keys.

local data = require 'database_driver'
local GetSessionKey = require 'apiframework.v1.lua.util.getSessionKey'

local function SessionTimeOut()
   return os.getenv('Session_Timeout') or 3600;
end

local function CreateSession(UserId, DB)
   -- Okay now we need to create a session and insert it into the session table
   local SessionId = util.guid(128)
   local ExpiryTime = os.ts.time() + SessionTimeOut() -- in seconds
   trace(ExpiryTime)
   
   data.CreateSession(SessionId, UserId, ExpiryTime);   
   return SessionId   
end

local function Login(R, S)
   local Name = R.params.Name
   local Password = R.params.Password
   if (not Name or #Name == 0) then
      return {Success=false, Message="Please enter your name."}
   end
   if (not Password) then
      return {Success=false, Message="Please enter your password."}
   end
   
   local WebInfo = iguana.webInfo()
   local Url = 'http';
   if WebInfo.web_config.use_https then
      Url = Url .. "s"
   end
   Url = Url .. "://localhost:"..WebInfo.web_config.port.."/monitor_query"

   local Result, Success = net.http.post{url=Url, parameters={UserName=Name, 
                     Password=Password, random=util.guid(128), Compact='Y'},
      live=true}
   if Success ~= 200 then
      return {Success=false, Message="Invalid login"}
   end
   local SessionId = CreateSession(Name, DB)
   local SessionKey = GetSessionKey()
   iguana.logInfo("Created SessionID="..SessionId);
   local Result = {Success=true, SessionKey = SessionKey, SessionId = SessionId, Name=Name,
         RefreshTime=(SessionTimeOut() - 300)*1000}
   -- trigger refresh 5 minutes before the session times out
   return Result
end

return Login