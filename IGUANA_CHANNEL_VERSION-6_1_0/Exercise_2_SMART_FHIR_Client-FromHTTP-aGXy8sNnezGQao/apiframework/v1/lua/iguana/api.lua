local ValidateDateTime = require 'datetime_validator'

local valid = {}

local function ReadFile(Name)
   local F = io.open(Name)
   local C = F:read("*a")
   F:close()
   return C
end

local function GrammarFindCall(Calls, Path, Method)
   for i = 1,#Calls do
      local Call = Calls[i]
      if (Call.Path == Path and Call.Method == Method) then
         return Call
      end
   end
   error("The call " .. Method:upper() .. " " .. Path .. " does not exist.")
end

local function GrammarFindType(Types, Name)
   for i=1,#Types do
      local Type = Types[i]
      if (Type.Name == Name) then
         return Type
      end
   end
   error("The type " .. Name .. " does not exist.")
end

local function BuildMap(Members)
   local Map = {}
   for i=1,#Members do
      Map[Members[i].Name] = Members[i]
   end
   return Map
end

local function AddCallIndex(Index, Call, Types)
   Index['call'] = Index['call'] or {}
   Index['call'][Call.Path:lower()] = Index['call'][Call.Path:lower()] or {}
   
   local Entry = {}
   Entry.Node = Call
   Entry.GetParamMap = BuildMap(Call.GetParams)
   Entry.PostParamMap = BuildMap(Call.PostParams)
   Entry.BodyMemberMap = BuildMap(Call.BodyMembers)
   Entry.ResponseBodyMemberMap = BuildMap(Call.ResponseBodyMembers) -- TODO ?? is this the appropriate place to index response features ??
   
   Index['call'][Call.Path:lower()][Call.Method:lower()] = Entry
   trace(Index)
   return Entry
end

local function AddTypeIndex(Index, Type)
   Index['type'] = Index['type'] or {}
   Index['type'][Type.Name:lower()] = Index['type'][Type.Name:lower()] or {}
   
   local Entry = {}
   Entry.Node = Type
   Entry.MemberMap = BuildMap(Type.Members)
   Index['type'][Type.Name:lower()] = Entry
   return Entry
end

local function CreateArrayMT(Types, Instance, MemberDef, AddObjectFunction)
   local MT = {}
   MT.__index = function(t,k,v)
      if MemberDef.Array then
         local Count = #Instance[MemberDef.Name]
         for i=Count+1, k do
            AddObjectFunction(Types, Instance, MemberDef, i)   
         end
      else
         AddObjectFunction(Types, Instance, MemberDef, k)
      end
      return t[k]
   end
   setmetatable(Instance[MemberDef.Name], MT)
end

local function AddMember(Types, Instance, MemberDef, ArrayIndex)
   if MemberDef.Array then 
      if not Instance[MemberDef.Name] then
         Instance[MemberDef.Name] = {}  -- Create array
         if MemberDef.MemberType.Type ~= "Primitive" then
            CreateArrayMT(Types, Instance, MemberDef, AddMember)          
         end
      end
   end
   
   if MemberDef.MemberType.Type == "Primitive" then
      if MemberDef.Array then 
         if ArrayIndex then
            Instance[MemberDef.Name][ArrayIndex] = json.NULL
         end
      else
         Instance[MemberDef.Name] = json.NULL
      end
      return
   end
   

   if MemberDef.Array then
      if nil ~= ArrayIndex then
         Instance[MemberDef.Name][ArrayIndex]={}
      end
   else
      Instance[MemberDef.Name] = {}
   end

   local MemberNode = GrammarFindType(Types, MemberDef.MemberType.Name)
   for i=1, #MemberNode.Members do
      if MemberDef.Array then
         if ArrayIndex ~= nil then
            AddMember(Types, Instance[MemberDef.Name][ArrayIndex], MemberNode.Members[i])  
         end
      else
         AddMember(Types, Instance[MemberDef.Name], MemberNode.Members[i])
      end
   end
end

local function NewCall(Calls, Types, Path, Method)
   local Instance = {}
   local Def = GrammarFindCall(Calls, Path, Method)
   Instance.post_params = {}
   for i=1,#Def.PostParams do
      Instance.post_params[Def.PostParams[i].Name] = {}
   end
   Instance.get_params = {}
   for i=1,#Def.GetParams do
      Instance.get_params[Def.GetParams[i].Name] = {}
   end
   -- ?? TODO ?? Handle the different body types ??
   Instance.body_members = {}
   for i=1,#Def.BodyMembers do
      AddMember(Types, Instance.body_members, Def.BodyMembers[i])
   end
   return Instance
end

local function NewResponse(Calls, Types, Path, Method)
   local Instance = {data={}}
   local Def = GrammarFindCall(Calls, Path, Method)
   trace(Def.ResponseType)
   for i=1,#Def.ResponseBodyMembers do
      AddMember(Types, Instance.data, Def.ResponseBodyMembers[i])
   end
   if Def.ResponseType == 'Resource' then
      Instance.data = Instance.data[next(Instance.data)]
   end

   return Instance
end

local function IndexFind(Index, Object)
   if (Object.Path and Object.Method) then
      return Index['call'][Object.Path:lower()][Object.Method:lower()], 'call'
   elseif (Object.Name) then
      return Index['type'][Object.Name:lower()], 'type'
   else
      error('This is an invalid object.') -- TODO ?? will this break the validation scheme?
   end
end

local function UnexpectedMemberError(Instance, Member, MemberMap)
   local ErrMessage = "The parameter '"..Member.."' is unexpected.  Expected parameters are "
   local Count = 0;
   for Member in pairs(MemberMap) do
      ErrMessage = ErrMessage .. Member.. " "
      Count = Count + 1
   end
   ErrMessage = ErrMessage:sub(1,#ErrMessage-1).. "."
   if Count == 0 then
      ErrMessage = "The parameter '"..Member.."' is unexpected.  No parameters were expected."
   end
   return ErrMessage
end

local function ValidateComposite(MT, MemberMap, Member, Instance, Path)
   local Node = MemberMap[Member]
   if type(Instance[Member]) ~= 'table' then
      return false, 'The field \'' .. Member .. '\' should be an object or an array with properties', Path, {name=Member, problem="Should be object"}
   end
   if Node.Array then
      for i=1, #Instance[Member] do
         Path[#Path+1] = i 
         local Success, Message, _, Info = valid.Validate(MT, Node.MemberType, Instance[Member][i], Path)
         if not Success then
            return Success, Message, Path, Info
         end
         Path[#Path] = nil
      end
   else       
      local Success, Message, Path, Info = valid.Validate(MT, Node.MemberType, Instance[Member], Path)
      if not Success then
         return Success, Message, Path, Info
      end
   end
   return true
end

local AllowedBoolean={}
AllowedBoolean[true] = true
AllowedBoolean[false] = true
AllowedBoolean[json.NULL] = true

local MapBoolean={}
MapBoolean["true"] = true
MapBoolean["false"] = false

local function ValidatePrimitive(MT, Type, Member, Instance, Path, Cast)
   if Type == "String" then
      if type(Instance[Member]) ~= 'string' and Instance[Member] ~= json.NULL then
         return false, Member.." must be a string.", Path, {problem="badprimitive", name=Member}    
      end
   end
   if Type == "Boolean" then
      if Cast and type(Instance[Member]) == "string" then
         local Value = MapBoolean[Instance[Member]]
         if Value == nil then
            return false, Member.." must be a boolean.", Path, {problem="badprimitive", name=Member}
         end
         Instance[Member] = Value
      end
      if not AllowedBoolean[Instance[Member]] then
         return false,  Member.." must be a boolean.", Path, {problem="badprimitive", name=Member}
      end
   end
   if Type == "Numeric" then
      if Cast and type(Instance[Member]) == "string" then
         local CastValue = tonumber(Instance[Member])
         if Instance[Member] ~= tostring(CastValue) then
            return false, Member.." must be a number.", Path, {problem="badprimitive", name=Member}
         else 
            Instance[Member] = CastValue
            return true
         end
      end
      
      if Instance[Member] ~= json.NULL and type(Instance[Member]) ~= 'number' then
         return false, Member.." must be a number.", Path, {problem="badprimitive", name=Member}         
      end
   end
   if Type == "DateTime" then
      local Cast = true
      local Success, ErrMessage = ValidateDateTime(Instance, Member, Cast)
      if not Success then
         ErrMessage = Member.." "..ErrMessage
         return false, ErrMessage, Path, {problem="badprimitive", name=Member}
      end
   end
   return true
end

local function CheckPresentMembers(MT, Instance, MemberMap, Path, Cast)
   local Success, Message
   if type(Instance) ~= 'table' then
      return true
   end
   for Member in pairs(Instance) do
      Path[#Path+1] = Member
      if not MemberMap[Member] then
         return false, UnexpectedMemberError(Instance, Member, MemberMap), Path, {problem="Unexpected", name=Member}
      end
      if (not MemberMap[Member].MemberType) then -- FOR PARAMETERS ONLY
         Success, Message, CPath, Info =  ValidatePrimitive(MT, MemberMap[Member].Type, Member, Instance, Path, Cast)
      else
         if MemberMap[Member].MemberType.Type ~= "Primitive" then
            Success, Message, CPath, Info =  ValidateComposite(MT, MemberMap, Member, Instance, Path)
         else 
            if MemberMap[Member].Array then  
               for i=1,#Instance[Member] do
                  Path[#Path+1] = i
                  Success, Message, CPath, Info =  ValidatePrimitive(MT, MemberMap[Member].MemberType.Name, i, Instance[Member], Path, Cast)
                  if not Success then
                     return Success, Message, CPath, Info     
                  end
                  Path[#Path] = nil
               end
            else
               Success, Message, CPath, Info =  ValidatePrimitive(MT, MemberMap[Member].MemberType.Name, Member, Instance, Path, Cast)
            end
         end
      end
      if not Success then
         return Success, Message, CPath, Info
      end
      Path[#Path] = nil
   end
   return true
end

local function CheckRequired(MemberMap, Instance, Path)
   for Member in pairs(MemberMap) do
      trace(Member)
      if MemberMap[Member].Required then
         if Instance[Member] == nil then
            return false, "Required parameter '"..Member.."' is not present.", Path, {name=Member, problem="missing"}
         end
         if Instance[Member] == '' then
            Path[#Path+1] = Member
            return false, "Required parameter '"..Member.."' is empty.",       Path, {name=Member, problem="badprimitive"}
         end
         if Instance[Member] == json.NULL then
            Path[#Path+1] = Member
            return false, "Required parameter '"..Member.."' cannot be null.", Path, {name=Member, problem="badprimitive"}
         end
      end
   end   
   return true
end

local function MemberValidator(MT, Instance, MemberMap, Path, Cast)
   local Success, Message, CPath, Info = CheckPresentMembers(MT, Instance, MemberMap, Path, Cast)
   if not Success then
      return Success, Message, CPath, Info
   end
   return CheckRequired(MemberMap, Instance, Path)
end

local function ResourceValidator(MT, Instance, ParentMap, Path)
   local Def = IndexFind(MT.GIndex, ParentMap.MemberType)
   if ParentMap.Array then
      for i=1,#Instance do
         return MemberValidator(MT, Instance[i], Def.MemberMap, Path)
      end
   else
      return MemberValidator(MT, Instance, Def.MemberMap, Path)
   end
end

function ValidateResponse(MT, Obj, Instance, Path)
   local Path = Path or {}
   local Def, Branch = IndexFind(MT.GIndex, Obj)
   trace(Def)
   if Def.Node.ResponseType == 'Resource' then
      return ResourceValidator(MT, Instance, Def.ResponseBodyMemberMap[next(Def.ResponseBodyMemberMap)], Path)
   end
   return MemberValidator(MT, Instance, Def.ResponseBodyMemberMap, Path)
end

local function BuildValidators(MT, Obj)
   local V = {}
   trace(Obj.Path)
   local Def = IndexFind(MT.GIndex, Obj)
	
   V.get_params = function(Call, Instance, Request) 
      local Success, Message, Path, Info = MemberValidator(MT, Instance, Def.GetParamMap, {}, true)
      if not Success then
         Info.location = 'URI'
         Info.datatype = 'URI encoded parameter'
         Info.path = Path
         Info.message = Message
         return Success, Info
      end
      Call.params = Instance
      return true
   end
   if Obj.BodyType == 'Parameters' then
      V.post_params = function(Call, Instance, Request)
         local Success, Message, Path, Info = MemberValidator(MT, Instance, Def.PostParamMap, {}, true)
         if not Success then
            Info.location = 'Request Body'
            Info.datatype = 'URI encoded parameter'
            Info.path = Path
            Info.message = Message
            return Success, Info
         end
         Call.data = Instance
         return true
      end
   elseif Obj.BodyType == 'Resource' then
      V.body = function(Call, Instance, Request)
         local next = next
         local Success, Message, Path, Info = ResourceValidator(MT, Instance, Def.BodyMemberMap[next(Def.BodyMemberMap)], {})
         if not Success then
            Info.location = 'Request Body'
            Info.datatype = 'JSON'
            Info.path = Path
            Info.message = Message
            return Success, Info
         end
         Call.data = Instance
         return true
      end
   elseif Obj.BodyType == 'Structured' then
      V.body = function(Call, Instance, Request)
         local Success, Message, Path, Info = MemberValidator(MT, Instance, Def.BodyMemberMap, {})
         if not Success then
            Info.location = 'Request Body'
            Info.datatype = 'JSON'
            Info.path = Path
            Info.message = Message
            return Success, Info
         end
         Call.data = Instance
         return true
      end
   end
   
   return V
end

function valid.Validate(MT, Obj, Instance, Path, IsResponse)
   local Def, Branch = IndexFind(MT.GIndex, Obj)
   trace(Def)
   if (type(Instance) == 'string') then
      return false, "Received string data. Should be a object with sub values", Path, {name=Path[#Path], problem="Incorrect type"}
   end
   if Branch == 'type' then
      return MemberValidator(MT, Instance, Def.MemberMap, Path, Cast)
   end
   
   if IsResponse then
      if Def.Node.ResponseType == 'Resource' then
         local Resource = GrammarFindType(MT.Grammar.Data.Types, Def.Node.ResponseBodyMembers[1].MemberType.Name)
         local MemberMap = BuildMap(Resource.Members)
         local IsArray = Def.ResponseBodyMemberMap[next(Def.ResponseBodyMemberMap)].Array
         if IsArray then
            for i=1,#Instance do
               return MemberValidator(MT, Instance[i], MemberMap, Path)
            end
         else
            return MemberValidator(MT, Instance, MemberMap, Path)
         end
      else
         return MemberValidator(MT, Instance, Def.ResponseBodyMemberMap, Path)
      end
   else
      if Instance.params then
         Path = {'params'}
         local Cast = true
         local Success, Message, CPath, Info = MemberValidator(MT, Instance.params, Def.GetParamMap, Path, Cast)
         if not Success then
            return Success, Message, CPath, Info
         end
      end
      -- ?? TODO ?? check GET request with body ??
      
      if Obj.BodyType == 'Resource' then
         Path = {'data'}
         local Resource = GrammarFindType(MT.Grammar.Data.Types, Def.Node.BodyMembers[1].MemberType.Name)
         local MemberMap = BuildMap(Resource.Members)
         local IsArray = Def.BodyMemberMap[next(Def.BodyMemberMap)].Array
         if IsArray then
            for i=1,#Instance do
               return MemberValidator(MT, Instance.data[i], MemberMap, Path)
            end
         else
            return MemberValidator(MT, Instance.data, MemberMap, Path)
         end
      end
      
      if Obj.BodyType == "Structured" then
         Path = {'data'}
         return MemberValidator(MT, Instance.data, Def.BodyMemberMap, Path, Cast)
      end
      
      if Obj.BodyType == "Parameters" then
         Path = {'data'}
         local Cast = true
         return MemberValidator(MT, Instance.data, Def.PostParamMap, Path, Cast)
      end
  
      return true
   end
end

local function BuildCall(Calls, Types, Call, Grammar)
	Grammar[Call.Path:lower()] = Grammar[Call.Path:lower()] or {}
   Grammar[Call.Path:lower()][Call.Method:lower()] = Grammar[Call.Path:lower()][Call.Method:lower()] or {}
   local Entry = Grammar[Call.Path:lower()][Call.Method:lower()]
   
   Entry.response = function()
      local RMT = {__index={}}
      local R = NewResponse(Calls, Types, Call.Path, Call.Method)
      setmetatable(R, RMT)
      RMT.__index.validate = function (Instance)
         local Success, Err, Path, Info = ValidateResponse(getmetatable(Grammar), Call, Instance.data)
         if Success ~= nil and not Success then
            return Success, Err, Path, Info
         end
         return true
      end
      RMT.__index.error = function(Message)
         -- used to throw errors in the api/* handler modules.
         if type(Message) ~= "string" then
            error("The argument must be a string.")
         end
         if iguana.isTest() then
            -- no decoration required in the editor
            error(Message, 2)
         else
            -- Throw an error with a magic string in front of it
            -- the framework then knows how to strip this out.
            error("<<VALIDERROR]]"..Message, 2)
         end
      end
      
      return R      
   end
   
   Entry.validate = BuildValidators(getmetatable(Grammar), Call)
end

local function Build(Path)
   local FullPath = iguana.workingDir()..iguana.project.root()..iguana.project.guid().."/"..Path
   if not os.fs.access(FullPath) then
      FullPath = iguana.workingDir()..iguana.project.root().."other/"..Path
   end
   -- TODO throw error if file does not exist.
   local Content = ReadFile(FullPath) 
   local G = {}
   local MT = {}
   MT.Grammar = json.parse{data=Content}
   setmetatable(G, MT)
   
   MT.GIndex = {}
   local Calls = MT.Grammar.Data.Calls
   local Types = MT.Grammar.Data.Types
   
   for i=1,#Calls do
      local C = Calls[i]
      -- FIX for grammars where BodyType is not a string.
      if type(C.BodyType) ~= 'string' then
         C.BodyType = 'Structured'
      end
      AddCallIndex(MT.GIndex, C, Types)
      BuildCall(Calls, Types, C, G)
   end
   for i=1,#Types do
      AddTypeIndex(MT.GIndex, Types[i])
   end
   
   return G
end

return Build