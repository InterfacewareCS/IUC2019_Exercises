-- ************************************************** --
-- FHIRdb
--  Store FHIR profiles in a database for faster
--  access than over File I/O.
--
-- Trevor
-- ************************************************** --

local InitSql = {[[
   CREATE TABLE IF NOT EXISTS Profiles(
   ResourceName TEXT PRIMARY KEY,
   Type TEXT,
   ProfileJson TEXT
);
   ]],
   [[
   CREATE TABLE IF NOT EXISTS ProfileTypes(
   ResourceName TEXT PRIMARY KEY,
   Type TEXT
);
   ]],
   [[
   CREATE TABLE IF NOT EXISTS State(
   This INTEGER PRIMARY KEY DEFAULT 1,
   IsInitialized BOOLEAN
);
   ]]}

local IsInitSql = [[SELECT IsInitialized FROM State WHERE This=1;]]
local function SetIsInitSql(State)
   assert(type(State) == 'boolean')
   local StateVal = 0
   if State then StateVal = 1 end
   local Sql = [[INSERT OR REPLACE INTO State (This, IsInitialized) VALUES(1, ]] .. StateVal .. [[);]]
   return Sql
end

local DropSql = {
   [[
   DROP TABLE IF EXISTS Profiles;
   ]],
   [[
   DROP TABLE IF EXISTS ProfileTypes;
   ]]
}

local function InsertProfileSql(Db, Entry)
   local ResourceName = Entry.resource.id
   local ProfileJson = json.serialize{data=Entry.resource, compact=true}
   local EntryType = Entry.resource.kind
   local Sql = [[INSERT INTO Profiles(ResourceName, Type, ProfileJson) VALUES(]] .. 
   Db:quote(ResourceName) .. [[, ]] .. 
   Db:quote(EntryType) .. [[, ]] ..
   Db:quote(ProfileJson) .. [[);]]
   return Sql
end

local function InsertProfileKeySql(Db, Entry)
   local ResourceName = Entry.resource.id
   local EntryType = Entry.resource.kind
   local Sql = [[INSERT INTO ProfileTypes(ResourceName, Type) VALUES(]] .. 
   Db:quote(ResourceName) .. [[, ]] .. 
   Db:quote(EntryType) .. [[);]]
   return Sql
end

local function ListResourceNamesSql(Db, TypeSpec)
   local Sql = [[SELECT ResourceName FROM ProfileTypes]]
   if TypeSpec then
      Sql = Sql .. [[ WHERE Type=]] .. Db:quote(TypeSpec)
   end
   Sql = Sql .. [[;]]
   return Sql
end

local function ListResourceTypesSql(Db, ResourceNameSpec)
   local Sql = [[SELECT DISTINCT Type FROM ProfileTypes]]
   if ResourceNameSpec then
      Sql = Sql .. [[ WHERE ResourceName=]] .. Db:quote(ResourceNameSpec)
   end
   Sql = Sql .. [[;]]
   return Sql
end

local function GetProfileSql(Db, ResourceName)
   local Sql = [[SELECT * FROM Profiles WHERE ResourceName=]] .. Db:quote(ResourceName) .. [[;]]
   return Sql
end

local function ConvertResultSet(ResultSet)
   local R = {}
   for i=1,#ResultSet do
      local Entry = {}
      local Row = ResultSet[i]
      for j=1,#Row do
         Entry[Row[j]:nodeName()] = Row[j]:nodeValue()
      end
      table.insert(R, Entry)
   end
   return R
end

local function GetProfileJson(ResultSet)
   for i = 1,#ResultSet do
      ResultSet[i].ProfileJson = json.parse{data=ResultSet[i].ProfileJson}
   end
   return ResultSet
end

local function GetResourceNamesList(ResultSet)
   local List = {}
   for i=1,#ResultSet do
      table.insert(List, ResultSet[i].ResourceName)
   end
   return List
end

local function GetResourceTypesList(ResultSet)
   local List = {}
   for i=1,#ResultSet do
      table.insert(List, ResultSet[i].Type)
   end
   return List
end

local function FHIRdb(DatabaseName)
   local m_Name = DatabaseName or iguana.project.gui() .. "_fhirdb"
   local m_Db
   local Interface = {}

   local function getConnection()
      if m_Db == nil or (m_Db.check ~= nil and m_Db:check() == false) then
         m_Db = db.connect{api=db.SQLITE, name=m_Name .. '.db'}
      end
   end

   local function closeConnection()
      m_Db:close()
   end

   local methods = {}
   setmetatable(Interface, {__index=methods})

   function methods:isInitialized()
      local f=io.open(m_Name .. '.db',"r")
      if f ~=nil then 
         getConnection()
         local Sql = IsInitSql
         local Result = nil
         Result = m_Db:query{sql=Sql, live=true}
         Result = ConvertResultSet(Result)
         closeConnection()
         trace(Result[1])
         if Result[1].IsInitialized == '1' then
            return true
         else
            return false
         end
      else 
         return false
      end
   end

   function methods:setIsInitialized(State)
      getConnection()
      local Sql = SetIsInitSql(State)
      m_Db:execute{sql=Sql, live=true}
      closeConnection()
   end

   function methods:dropTables()
      getConnection()
      for i=1,#DropSql do
         m_Db:execute{sql=DropSql[i], live=true}
      end
      closeConnection()
   end

   function methods:init(Profiles)
      getConnection()
      for i=1,#InitSql do
         m_Db:execute{sql=InitSql[i], live=true}
      end
      for i=1,#Profiles.entry do
         local Sql = InsertProfileSql(m_Db, Profiles.entry[i])
         m_Db:execute{sql=Sql, live=true}
         Sql = InsertProfileKeySql(m_Db, Profiles.entry[i])
         m_Db:execute{sql=Sql, live=true}
      end
      closeConnection()
   end

   -- get a profile for a given resource (or type)
   function methods:get(ResourceName)
      getConnection()
      local Sql = GetProfileSql(m_Db, ResourceName)
      local Result = m_Db:query{sql=Sql, live=true}
      assert(#Result == 1 and Result[1].ProfileJson ~= nil)
      closeConnection()
      Result = ConvertResultSet(Result)
      return GetProfileJson(Result)[1].ProfileJson
   end

   function methods:listResourceNames(TypeSpec)
      getConnection()
      local Sql = ListResourceNamesSql(m_Db, TypeSpec)
      local Result = m_Db:query{sql=Sql, live=true}
      closeConnection()
      Result = ConvertResultSet(Result)
      return GetResourceNamesList(Result)
   end

   function methods:listResourceTypes(TypeSpec)
      getConnection()
      local Sql = ListResourceTypesSql(m_Db, TypeSpec)
      local Result = m_Db:query{sql=Sql, live=true}
      closeConnection()
      Result = ConvertResultSet(Result)
      return GetResourceTypesList(Result)
   end

   function methods:isType(ExpectedType, TypeName)
      getConnection()
      local Sql = ListResourceTypesSql(m_Db, TypeName)
      local Result = m_Db:query{sql=Sql, live=true}
      Result = ConvertResultSet(Result)
      if #Result ~= 1 then
         return false
      end
      closeConnection()
      return Result[1].Type == ExpectedType
   end

   return Interface
end

return FHIRdb