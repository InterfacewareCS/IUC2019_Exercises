local ApiInit = require 'apiframework.v1.lua.iguana.api'
local Auth = require 'apiframework.v1.lua.util.checkToken'

-- The generated API uses SQLite to create the authorization tokens.  This code is all in one place
-- to make it easy to switch to a different front end.
local data     = require 'database_driver'
data.Create()   -- Intialize the session and token database if necessary.

local web = {}

web.webserver = {}

local webMT = {__index=web.webserver}

local function ReadFile(FileName) 
   local F=io.open(FileName, "rb")
   local Content = F:read('*a')
   F:close()
   return Content
end

local function WriteFile(FileName, C)
   local F = io.open(FileName, "wb")
   F:write(C)
   F:close()
end

local function ServeError(ErrMessage, Code, RawRequest)
   local Args = {code = Code}
   if ErrMessage then
      local Body = {error = ErrMessage}
      Args.body = json.serialize{data = Body}
      Args.entity_type = 'text/json'
   end
   net.http.respond(Args)
   -- Only log internal errors
   if Code > 499 then
      local ErrId = queue.push{data = RawRequest}
      iguana.logError(ErrMessage, ErrId)
   end
end

local function DoFileAction(Self, R, Data)   
   local Action = R.location:sub(Self.baseUrlSize)
   local Func = Self.actions[Action]
   trace(Func)
   if (Func) then
      local Result = Func(R, Self, Data)
      if Result.alreadyHandled then
         return true
      end
      if Result.error then 
         ServeError(Result.error, Result.code, Data)
         return true
      end
      Result = json.serialize{data=Result, compact=true}
      net.http.respond{body=Result, entity_type='text/json'}   
      return true
   end
   return false
end

local function AddElementToPathString(PathString, Element)
   local PathElements
   if #PathString > 0 then
      PathElements = PathString:split('/')
   else
      PathElements = {}
   end
   PathElements[#PathElements+1] = Element
   return table.concat(PathElements, '/')
end

local function DoRequire(ActionTable, Method, PathParams, PathHash)
   local A = ActionTable[Method]
   if not A then
      return false
   end
   local EntityType = type(A)
   if EntityType == 'string' then
      local Success, Func = pcall(require, A)
      if Success then
         return Func, PathParams, PathHash
      else
         ActionTable[Method] = {Err=Func}
         error(Func)
      end
   end
   if EntityType == 'table' then
      error(A.Err)
   end
end

local function LoadAction(ActionTable, Path, Method, PathParams, PathHash)
   local PathParams = PathParams or {}
   local PathHash = PathHash or ''
   if type(Path) == 'string' then
      Path = Path:split('/')
   end
   if #Path >= 1 then
      local Element = table.remove(Path,1)
      local AT = ActionTable[Element]
      if AT then
         PathHash = AddElementToPathString(PathHash, Element)
         return LoadAction(AT, Path, Method, PathParams, PathHash)
      else
         AT = ActionTable['{id}']
         if AT then
            PathHash = AddElementToPathString(PathHash, '{id}')
            table.insert(PathParams, Element)
            return LoadAction(AT, Path, Method, PathParams, PathHash)
         else
            ActionTable[Element] = {Err="Invalid API Call"}
            return false
         end
      end
   else
      return DoRequire(ActionTable, Method, PathParams, PathHash)
   end
end

local function CountLines(Folder, PathHash, Method)
   local FileName = iguana.workingDir()..iguana.project.root()..iguana.project.guid().."/api/"..Folder.."/"..PathHash.."/"..Method..".lua"
   local C = ReadFile(FileName)
   local Lines = C:split("\n")
   return #Lines
end

local function ColumnPrint(Data)
   local R = ''
   local MaxWidth = 100;
   local Lines = Data:split("\r\n")
   local OutLines = {}
   for i=1,#Lines do
      local Line = Lines[i]
      if #Line > MaxWidth then
         OutLines[#OutLines+1] = Line:sub(1, MaxWidth).."..."
         for j=MaxWidth, #Line, MaxWidth do 
            local LinePart = " "..Line:sub(j+1, j+MaxWidth-1)
            if j + MaxWidth < #Line then
               LinePart = LinePart.."..."
            end
            OutLines[#OutLines+1] = LinePart
         end
      else
         OutLines[#OutLines+1] = Line
      end
   end
   
   return table.concat(OutLines, "\r\n")
end

local function HandleRequestBody(Self, Call, R, RawData)
   local Success, Data = pcall(json.parse, {data=R.body})
   if not Success then
      ServeError(Data, 400, RawData)
      return nil
   end
   for k,v in pairs(Data) do
      Call.body_members[k] = v
   end
   
   return Call
end

local function RaiseInputError(Message, Code, Data, Level)
   if iguana.isTest() then
      error(Message, Level)
   else
      ServeError(Message, Code, Data);
      return true
   end
end

local function PrintGet(RawData)
   return RawData:split("\r\n")[1]
end

local function ShowPath(Path)
   local R = ''
   for i=1, #Path do
      local Value = Path[i]
      if type(Value) == 'number' then
         R = R..'['..Value..']'
      else
         R=R.."."..Value
      end
   end
   return R:sub(2,#R)
end

local function HandleInputError(Info, Request)
   local Header = Request.method .. ' ' .. Request.location
   local Err = 'Request Failed: ' .. Header
   trace(Err, Info)
   if Info.message then
      Err = Err .. '\nReason: ' .. Info.message
   end
   if Info.location then
      Err = Err .. '\nLocation: ' .. Info.location
      if Info.datatype then
         Err = Err .. ' (' .. Info.datatype .. ')'
      end
   end
   if Info.datatype == 'JSON' and Info.path and #Info.path > 0 then
      Err = Err .. '\nPath: ' .. ShowPath(Info.path)
   end
   
   return Err
end

local function ParseJsonBody(Request)
   local Success, Body = pcall(json.parse, {data=Request.body})
   if not Success then
      local Info = {}
      local Err =[[The HTTP message body needs to have the call parameters encoded in JSON. The body content could not be parsed as JSON.]]
      if #Request.body > 0 then
         Err = Err.." Length of body received = "..#Request.body
      else
         Err = [[The body of the HTTP message received was empty. It is meant to have the parameters for the call encoded in JSON.  Like {} or [] if there are no parameters.]]
      end
      Info.message = Err
      Info.location = 'Request Body'
      Info.datatype = 'JSON'
      return false, HandleInputError(Info, Request)
   end
   return true, Body
end

local function CheckBodyParams(Request)
   local ContentType = Request.headers["Content-Type"]
   if ContentType:find('application/x-www-form-urlencoded') then
      local Info = {}
      Info.message = "URI encoded parameters were expected in the request body, but the Header 'Content-Type: application/x-www-form-urlencoded' was not included. Please include this header."
      if ContentType then
         Info.message = Info.message .. " The Content-Type received was '" .. ContentType .. "'."
      end
      Info.location = 'Headers'
      Info.datatype = "URI encoded parameteres"
      return false, HandleInputError(Info, Request, RawData)
   end
   
   local ContentLength = Request.headers["Content-Length"]
   if ContentLength then ContentLength = tonumber(ContentLength) else return true end
   if ContentLength > 0 and not next(Request.post_params) then
      local Info = {}
      Info.message = "URI encoded parameters were expected in the request body."
      Info.location = 'Request Body'
      Info.datatype = "URI encoded parameters"
      return false, HandleInputError(Info, Request, RawData)
   end
   
   return true
end

local function Validate(Self, R, RawData, PathHash)
   trace(getmetatable(Self.G).GIndex.call[PathHash])
   local Grammar = getmetatable(Self.G).GIndex.call[PathHash][R.method:lower()].Node
   trace(Grammar)
   local Call = {}
   -- We just have a custom handler:
   if Grammar.BodyType == 'Custom' then
      return RawData
   end
   for k,v in pairs(Self.G[PathHash][R.method:lower()].validate) do
      trace(k,v)
      local Data = R[k]
      local Success
      if k == 'body' and (Grammar.BodyType == 'Resource' or Grammar.BodyType == 'Structured') then
         Success, Data = ParseJsonBody(R)
         if not Success then 
            RaiseInputError(Data, 400, RawData, 7) 
            return false
         end
      end
      if k == 'post_params' then
         Success, Message = CheckBodyParams(R)
         if not Success then 
            RaiseInputError(Message, 400, RawData, 7)
            return false
         end
      end
      local Success, Info = v(Call, Data, R)
      if not Success then
         RaiseInputError(HandleInputError(Info, R), 400, RawData, 7)
         return false
      end
   end
   
   return Call
end

local function CheckAuthentication(R)
   local Success, Err = Auth(R) 
   if not Success and not iguana.isTest() then
      ServeError(Err, 401, RawData)        
      return false;
   end
   return true
end

local function PrepareCall(Self, R, RawData, PathHash, PathParams, Method)
   local Call = Validate(Self, R, RawData, PathHash)
   if not Call then
      return false
   end
   if #PathParams > 0 then
      Call.path = PathParams
   end
   Call.response = Self.G[PathHash][Method].response 
   return true, Call
end

local function CleanJsonNull(Obj)
   local rvs = {}
   for k,v in pairs(Obj) do
      if type(Obj[k]) == 'table' then
         rvs[#rvs+1], _ = CleanJsonNull(Obj[k])
         Obj[k] = not rvs[#rvs] and Obj[k] or nil
      elseif Obj[k] == json.NULL then
         Obj[k] = nil
         rvs[#rvs+1] = true
      else
         rvs[#rvs+1] = false
      end
   end
   local retval = true
   for i = 1,#rvs do
      if not rvs[i] then retval = false break end
   end
   return retval, Obj
end

local function ThrowResponseError(Self, PathHash, Method, Message, Info, Path, RawData)
   local Err
   if not Path then
      Err = 'There was no Response.'
   else
      Err = "Problem in "..ShowPath(Path).."\n"..Message
   end
   iguana.logError(Err);
   if iguana.isTest() then
      local LineNumber = CountLines(Self.folder, PathHash, Method)-1;
    error([[<<>><$#$$REQUIREPROBLEM&*^*&^[string "api]]..[[/]]..Self.folder..[[/]]..PathHash..[[/]]..Method..[[.lua"]:]]
         ..LineNumber..[[: ]].."Response violates the grammar:\n"..Err)
   end
   iguana.logError("Serving response error.")
   ServeError("While generating response:\n"..Err, 500, RawData)
   return true
end

local NoTokenAuth = {
	--["hspc/launch"]=true,
   --["hspc/redirect"]=true
}

local function DoApiAction(Self, R, RawData)
   local Method = R.method:lower() 
   local Action, PathParams, PathHash = LoadAction(Self.api, R.location:sub(Self.baseUrlSize):lower(), Method)
   if Action == false then
      return false
   end
   if not NoTokenAuth[PathHash] and not CheckAuthentication(R) then 
      return true
   end
   local Success, Call = PrepareCall(Self, R, RawData, PathHash, PathParams, Method)
   if not Success then
      return true
   end
   local Result 
   iguana.logInfo(RawData)
   if iguana.isTest() then
      Result = Action(Call, Self.app)
   else
      local Success
      Success, Result = pcall(Action,Call, Self.app)
      if not Success then
         if type(Result)== 'string' then
            -- Strip off location
            Result = Result:rxsub(".*<<VALIDERROR]]", "")
         elseif type(Result) == 'table' then
            Result = json.serialize{data=Result}
         end
         ServeError(Result, 500, RawData)
         return true
      end
   end
   if Result.has_responded then
      return true
   end
   iguana.logInfo("Validating response.");
   -- Make sure what came out of the API call implements what the grammar says
   CleanJsonNull(Result.data)
   local Success, Message, Path, Info = Result:validate()
   if not Success then
      iguana.logInfo("Failed validation");
      return ThrowResponseError(Self, PathHash, Method, Message, Info, Path, RawData)
   end
   Result = json.serialize{data=Result, compact=true}
   net.http.respond{body=Result, entity_type='text/json'}   
   return true
end

-- This is the old load action function which is still used for the
-- flat action table
local function LoadActionApi(ActionTable, Action)
   local Entry = ActionTable[Action]
   local EntryType = type(Entry)
   if EntryType == 'string'  then
      local Success, Func = pcall(require, Entry)
      if Success then
         ActionTable[Action] = Func
      else
         -- we need to cache errors otherwise we won't see
         -- the require error in place
         ActionTable[Action] = {Err=Func}
         error(Func);
      end
   end
   if EntryType == 'table' then
      error(Entry.Err);
   end
end

local function DoJsonAction(Self, R, Data) 
   iguana.logInfo(Data)
   local Action = R.location:sub(Self.baseUrlSize)
   local Func = Self.actions[Action]
   trace(Func)
   if (Func) then
      LoadActionApi(Self.actions, Action)
      local Success, Result = pcall(Self.actions[Action], R, Self)
      if not Success then
         local Message = "An internal error occured."
         ServeError(Message, 500, Data)
         return true
      end
      if Result.alreadyHandled then
         return true
      end
      if Result.error then 
         ServeError(Result.error, Result.code, Data)
         return true
      end
      Result = json.serialize{data=Result, compact=true}
      net.http.respond{body=Result, entity_type='text/json'}   
      return true
   end
   return false
end

local ContentTypeMap = {
   ['.js']   = 'application/javascript',
   ['.css']  = 'text/css',
   ['.gif']  = 'image/gif',
   ['.png']  = 'image/png',
   ['.jpg']  = 'image/jpeg',
   ['.jpeg'] = 'image/jpeg',
   ['.htm']  = 'text/html',
   ['.html'] = 'text/html',
   ['.svg']  = 'image/svg+xml'
}

local function FindEntity(Location) 
   local Ext = Location:match('.*(%.%a+)$')
   local Entity = ContentTypeMap[Ext]
   return Entity or 'text/plain'
end

local function LoadIguanaFile(FileName) 
	local RootDir = iguana.appDir() .. 'web_docs/'
   local Path = os.fs.abspath(RootDir..FileName)
   if (Path:sub(1, #RootDir) ~=RootDir) then
      -- we have an above root attack
      return
   end
      if (os.fs.stat(Path)) then
      return ReadFile(Path)
   end
end

local function LoadMilestonedFile(FileName) 
   -- TODO This could be simplified if Iguana 6 iguana.project.files() gave
   -- the local directory 
   local Guid = iguana.project.guid()
   local FilePath = iguana.workingDir()..'run/'..Guid..'/'..Guid..'/apiframework/v1/web/'..FileName
   if (os.fs.stat(FilePath)) then
      return ReadFile(FilePath)
   end
   FileName = iguana.project.files()["other/"..FileName]
   trace(FileName)
   if FileName then
      return ReadFile(FileName);
   end
   return nil
end

local function LoadSandboxFile(FileName, User)
   local Guid = iguana.project.guid()
   local RootDir = iguana.workingDir()..'edit/'..User..'/'..Guid..'/apiframework/v1/web/'
   local Path = os.fs.abspath(RootDir..FileName)
   if (Path:sub(1, #RootDir) ~=RootDir) then
      -- we have an above root attack
      return 
   end
   if (os.fs.access(Path)) then
      -- it was a local dependency.
      return ReadFile(Path)
   end
   return nil
end

local function ServeFile(Self, R)
   local FileName = R.location:sub(Self.baseUrlSize)
   if #FileName == 0 then 
      FileName = Self.default 
   end
   
   local Content
   if Self.test then 
      Content = LoadSandboxFile(FileName, Self.test)
   else
      Content = LoadMilestonedFile(FileName)
   end
   if not Content then 
      Content = LoadIguanaFile(FileName)
   end
   local Entity = FindEntity(FileName)
   trace(Content)
   if (Content) then
      net.http.respond{body=Content, entity_type=Entity}
      return true
   end
   return false
end

local function KnownApiSet(Self)
   local apis = {}
   local Calls = {}
   
   for Path,Set in pairs(Self.G) do
      trace(Path, Set)
      apis[Path] = apis[Path] or {}
      local M = Self.baseUrl .. Path .. " ("
      for Method in pairs(Set) do
         trace(Method)
         apis[Path][#apis[Path]+1] = Method:upper()
         M = M .. Method:upper() .. ", "
      end
      M = M:sub(1,#M-2) .. ")"
      Calls[#Calls+1] = M
   end
   table.sort(Calls)
   return table.concat(Calls, "\n")
end

local function KnownApi(Self, R)
   local M = R.method
   
   M = M.." "..R.location.. [[ is not a supported call.
   
See:
https://designer.interfaceware.com/#overview?ApiId=]]..getmetatable(Self.G).Grammar.ApiId
   M = M.."\n"..KnownApiSet(Self)
   return M
end

local function ServeRequest(Self, P)
   local Success, R = pcall(net.http.parseRequest, {data=P.data})
   if not Success then
      if R == 'HTTP response body is incomplete.' then
         ServeError('Bad Request: ' .. R .. ' Check that the body of your request has the same length as the \'Content-Length\' header.', 400, P.data)
      else
         ServeError('Bad Request', 400, P.data) -- ?? TODO ?? I am not sure where else the net.http.parseRequest can fail.
      end
      return
   end
   -- To get file upload working
   if R.headers["Content-Type"] and 
      R.headers["Content-Type"]:sub(1,19) == 'multipart/form-data' then
      if not DoFileAction(Self, R, P.data) then
         ServeError('Bad request', 400, P.data)
      end
      return
   end
   if DoApiAction(Self, R, P.data) then return 'Served Api' end
   if DoJsonAction(Self, R, P.data) then return 'Served Json' end
   if ServeFile(Self, R) then return 'Served file' end
   local Message = KnownApi(Self, R)
   if iguana.isTest() then
      error(Message,3)
   end
   ServeError(Message, 400, P.data)
   return 'Bad request'
end

-- Find the method for the action.
function web.webserver.serveRequest(Self, P)
   if iguana.isTest() then
      return ServeRequest(Self, P)
   else
      -- When running, push full stack error out to browser.
      -- In the case of an internal error, log it.
      local Stack = nil
      local Success, ErrMsg = pcall(ServeRequest, Self, P)
      if (not Success) then
         local Message
         if type(ErrMsg) == 'table' then
            Message = json.serialize{data=ErrMsg}
         else
            Message = tostring(ErrMsg)
         end
         if (Self.mode == 'debug') then
            ServeError(Message, 500, P.data)
         else
            ServeError('An internal error occured.', 500, P.data)
         end
      end
   end
end

local Cache = {}

local function HasGrammarFileChanged(T)
   if not iguana.isTest() then
      return false
   end
   local GrammarFile = T.grammar
   if GrammarFile == nil then
      return false
   end
   local FileName = iguana.workingDir()..iguana.project.root()
   ..iguana.project.guid().."/"..GrammarFile
   local Grammar = ReadFile(FileName)
   local NewChecksum = util.md5(Grammar)
   local Result = not(T.Checksum == NewChecksum)
   T.Checksum = NewChecksum
   return Result
end

local function CreateDefaultActions(T)
   T.actions = {
      _login         = 'apiframework.v1.lua.api._login',
      _logout        = 'apiframework.v1.lua.api._logout', 
      _checkSession  = 'apiframework.v1.lua.api._checkSession',
      _loadTemplates = 'apiframework.v1.lua.api._loadTemplates',
      _grammar       = 'apiframework.v1.lua.api._grammar',
      _grammarHash   = 'apiframework.v1.lua.api._grammarHash',
      _generateToken = 'apiframework.v1.lua.api._generateToken',
      _checkToken    = 'apiframework.v1.lua.api._checkToken',
      _listTokens    = 'apiframework.v1.lua.api._listTokens',
      _removeToken   = 'apiframework.v1.lua.api._removeToken',
      _saveClientId  = 'apiframework.v1.lua.api._saveClientId'
   }
   T.actions[''] = 'apiframework.v1.lua.api._index'
end

local function CheckVersion()
   local V = iguana.version()
   local D = V.major * 10000 + V.minor * 100 + V.build
   trace(D)
   if D < 60000 then
      iguana.stopOnError(true);
      error('Sorry this script requires Iguana 6.0 or greater.');
   end
end

local function CalcBaseUrl()
   CheckVersion()
   local Config = iguana.channelConfig{guid=iguana.channelGuid()}
   Config = xml.parse{data=Config}
   BaseUrl = '/'..tostring(Config.channel.from_http.mapper_url_path)
   if BaseUrl:sub(#BaseUrl) ~= '/' then
      iguana.stopOnError(true)
      error('Please reconfigure the channel to have the base URL path '..BaseUrl..'/');
   end
   return BaseUrl
end

local function MakeDir(Dir)
   os.fs.mkdir(Dir)
end

local function MakeFolder(FileName)
   local Parts = FileName:split("/")
   local Dir = ""
   for i=1, #Parts-1 do
      Dir = Dir..Parts[i].."/"
      trace(Dir)
      local Stat = os.fs.stat(Dir)
      if Stat and not Stat.isdir then
         error("We have a serious problem: "..Dir.." exists, but it is not a directory.")
      end
      if not Stat then
         MakeDir(Dir)
      end      
   end
end

local function CreateHandler(Folder, Path, Method, Doc)
   local PathList = Path:split('/')
   local FName = PathList[1]:capitalize()
   local C = '-- Call '..Method:upper().." /"..Path:lower().."\n"
   C=C.."--[[ "..Doc:trimWS().."]]\n\n"
   C = C..[[function ]]..FName.."(Call, App)\n"
          .. [[   local Result = Call.response()
   
   -- TODO Write code to look at Call data and populate Result

   return Result
end

return ]]..FName
   local FileName = iguana.workingDir() .. iguana.project.root() .. iguana.project.guid() ..
      "/api/" .. Folder .. '/' .. Path:lower() .. '/' .. Method:lower() .. '.lua'
   trace(FileName)
   
   if not os.fs.access(FileName) then
      MakeFolder(FileName)
      WriteFile(FileName, C)       
   end
   
   require('api.'..Folder.."."..Path:gsub('/','.'):lower().."."..Method:lower())
   return C
end

local function FindDoc(Path, Method, Grammar)
   local Calls = Grammar.Grammar.Data.Calls
   for i=1, #Calls do
      local Call = Calls[i]
      if Call.Path:lower() == Path and Call.Method:lower() == Method then
         return Call.Description
      end
   end
   return ''
end

local function GenerateStubs(T)
   if not iguana.isTest() then 
      return -- We only generate stubs in the IDE.
   end
   local Start = os.clock()
   local Base = "api/"..T.folder.."/"
   local EList = iguana.project.files()
   trace(T.G)
 
   for Path,V in pairs(T.G) do
      trace(Path)
      for Method in pairs(V) do
         local HName = Base .. Path .."/"..Method..".lua"
         if EList[HName] == nil then
            trace(HName)
            trace(Path)
            local Doc = FindDoc(Path,Method, getmetatable(T.G))
            CreateHandler(T.folder, Path, Method, Doc)
         end
      end
   end
   trace(HList)
   local EndT = os.clock()
   trace(EndT-Start)
end

local function AddAction(ActionTable, Path, RequireString)
   trace(ActionTable)
   if #Path == 1 then
      local Element = table.remove(Path, 1):split('.')[1]
      ActionTable[Element] = RequireString .. '.' .. Element
   else
      local Element = table.remove(Path, 1)
      RequireString = RequireString .. '.' .. Element
      ActionTable[Element] = ActionTable[Element] or {}
      AddAction(ActionTable[Element], Path, RequireString)
   end
end

local function BuildActionTable(Files, Folder, ActionTable)
   local ActionTable = ActionTable or {}
   for k,v in pairs(Files) do
      local Path = k:split('/')
      if table.remove(Path,1) == 'api' and table.remove(Path,1) == Folder then
         trace(Path)
         AddAction(ActionTable, Path, 'api.'.. Folder)
      end
   end
   return ActionTable
end

local function CreateWebServer(T)
   local Start = os.clock()
   local HasGrammarChanged = HasGrammarFileChanged(T)
   if HasGrammarChanged then
      Cache = {} -- Invalidate cache
   end
   local EndTime = os.clock()
    
   if Cache[T] then
      --return Cache[T]  
   end
   iguana.stopOnError(false) 
   CreateDefaultActions(T)
   T.baseUrl = CalcBaseUrl()
   if T.grammar then
      T.G = ApiInit(T.grammar)
   end
   if HasGrammarChanged then
      GenerateStubs(T)
   end
   T.baseUrlSize = #T.baseUrl +1
   T.api = {}
   local ProjectFiles = iguana.project.files()
   BuildActionTable(ProjectFiles, T.folder, T.api)
   setmetatable(T, webMT)
   Cache[T] = T
   return T
end

return CreateWebServer