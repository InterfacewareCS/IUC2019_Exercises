-- To implement storing of Access tokens the API framework uses SQLlite out of the box
-- You can leave this 'as is' or if you would prefer to use a different database
-- then we have tried to make this easy for you by putting all the database
-- operations related to this need within this one file so you can change them in one place.

local data = {}

-- Establish a connection to the database.
function data.Connection()
   local DB = db.connect{api=db.SQLITE, 
      name=iguana.project.guid()}
   return DB   
end

-- This routine creates the database tables if they do not already exist.
local SQL={
   [[
   CREATE TABLE IF NOT EXISTS Sessions(
   SessionId text PRIMARY KEY,
   UserId text,
   Expiry    integer
);
   ]],
   [[
   CREATE TABLE IF NOT EXISTS AccessTokens(
   Id INTEGER PRIMARY KEY,
   Token text UNIQUE,
   Name text UNIQUE
);
   ]],
   [[
   CREATE TABLE IF NOT EXISTS Client(
   Id INTEGER UNIQUE PRIMARY KEY DEFAULT '1',
   ClientId TEXT UNIQUE,
   ClientUrl TEXT
);
   ]],
   [[
   CREATE TABLE IF NOT EXISTS ClientAccess(
   Id INTEGER UNIQUE PRIMARY KEY AUTOINCREMENT,
   LaunchId TEXT UNIQUE,
   Code TEXT UNIQUE,
   TokenEndpoint TEXT,
   AccessToken TEXT UNIQUE,
   Client INTEGER,
   StateGuid TEXT UNIQUE,
   FOREIGN KEY(Client) REFERENCES Client(Id)
);
   ]],
   [[
   CREATE TABLE IF NOT EXISTS ServerAccessToken(
   Id INTEGER UNIQUE PRIMARY KEY AUTOINCREMENT,
   access_token TEXT,
   token_type  TEXT,
   refresh_token  TEXT,
   expires_in  TEXT ,
   scope  TEXT,
   patient  TEXT,
   need_patient_banner TEXT,
   id_token TEXT,
   ClientAccessId TEXT UNIQUE,
   FOREIGN KEY(ClientAccessId) REFERENCES ClientAccess(LaunchId)
);
   ]],  
   [[
   CREATE TABLE IF NOT EXISTS Loinc(
   Id INTEGER UNIQUE PRIMARY KEY AUTOINCREMENT,
   ClinicalNoteType TEXT,
   GeneralCode  TEXT,
   ValueSetName  TEXT,
   Reference  TEXT
);
   ]],
   [[
CREATE TABLE IF NOT EXISTS SearchParams(
	Resource TEXT,
   SearchParam TEXT
);
CREATE INDEX IF NOT EXISTS search_param ON SearchParams(Resource);
   ]]
}--Should Change Client Access ID to Launch ID

function data.Create()
   local DB = data.Connection()
   for i = 1,#SQL do
      DB:execute{sql=SQL[i], live=true}
   end
   DB:close()
end

-- HELPER ROUTINE
local function ConvertResultSet(R)
   local Result = {}
   for i=1, #R do
      local Row = {}
      for j=1, #R[i] do
         local NodeType = R[i][j]:nodeType()
         if NodeType == 'string' then
            Row[R[i][j]:nodeName()] = R[i][j]:nodeValue() 
         elseif NodeType == 'integer' then
            Row[R[i][j]:nodeName()] = tonumber(R[i][j]:nodeValue()) 
         else
            error('We did not take into account non string and integer columns');
         end
      end

      Result[#Result+1] = Row
   end
   return Result
end

-- *** AUTHORIZATION TOKEN ROUTINES USED FOR THE API

--Loinc SQL
function data.ListLoinc()
   local DB = data.Connection()
   local SQL = 'SELECT ClinicalNotetype, GeneralCode, ValueSetName, Reference FROM "Loinc";'
   local R = DB:query{sql=SQL}
   DB:close()
   local Result = ConvertResultSet(R)
   return Result
end


--Loinc SQL

-- Server Access token SQL
function data.GetServerAccessToken(WhereKey, WhereVal)
   local DB = data.Connection()
   local SQL = [[SELECT * FROM ServerAccessToken WHERE ]] .. WhereKey .. [[=]] .. DB:quote(WhereVal) .. [[;]]
   local Result = ConvertResultSet(DB:execute{sql=SQL,live=true})
   DB:close()
   return Result
end

function data.ListServerAccessToken()
   local DB = data.Connection()
   local SQL = 'SELECT * FROM "ServerAccessToken";'
   local R = DB:query{sql=SQL}
   DB:close()
   local Result = ConvertResultSet(R)
   return Result
end

function data.InsertLaunchServerAccessToken(launch)
   local DB = data.Connection()
   local SQL = [[INSERT INTO "ServerAccessToken" ("ClientAccessId")  VALUES (]] ..DB:quote(launch) .. ")"
   DB:execute{sql=SQL}
   DB:close()
end

function data.InsertNewServerAccessToken(R, launch)
   local DB = data.Connection()
   local SQL = [[UPDATE ServerAccessToken SET access_token = ]]
   ..DB:quote(R.access_token) .. [[, token_type = ]] .. DB:quote(R.token_type) .. [[, refresh_token = ]] .. DB:quote(R.refresh_token) .. [[, expires_in = ]] .. DB:quote(R.expires_in) .. [[, scope = ]] .. DB:quote(R.scope) .. [[, patient = ]] 
   .. DB:quote(R.patient) .. [[, need_patient_banner = ]] .. DB:quote("true") .. [[, id_token = ]] .. DB:quote(R.id_token)  ..[[ WHERE ClientAccessId = "]] .. launch ..[["]]
   trace(SQL)
   DB:execute{sql=SQL, live=true}
   DB:close()
end 
--Fix true boolean to process properly

function data.DeleteServerAccessToken(TokenId)
   local DB = data.Connection()
   local SQL = [[DELETE FROM "AccessTokens" WHERE "Id"=]] .. DB:quote(TokenId) 
   DB:execute{sql=SQL}
   DB:close()
end
-- Server Access token SQL

-- This function returns true if the access token is valid.
function data.IsTokenValid(Token)
   local DB = data.Connection();
   local R = DB:query{sql=[[SELECT Token FROM "AccessTokens"]]..
      [[ WHERE "Token" = ]]..DB:quote(Token)}
   DB:close()
   return #R == 1
end

-- Returns true if an access token exists with the supplied name
function data.CheckAccessTokenNameExists(Name)
   local DB = data.Connection()
   local R = DB:query{sql=[[SELECT * FROM "AccessTokens" WHERE "Name"=]]..DB:quote(Name)}
   DB:close()
   return #R==1
end

function data.InsertNewAccessToken(Name, Token)
   local DB = data.Connection()
   local SQL = [[INSERT INTO "AccessTokens" ("Token", "Name") VALUES (]]
   ..DB:quote(Token) .. [[,]] .. DB:quote(Name) .. ")" 
   DB:execute{sql=SQL}
   DB:close()
end   

function data.ListAccessTokens()
   local DB = data.Connection()
   local SQL = 'SELECT * FROM "AccessTokens";'
   local R = DB:query{sql=SQL}
   DB:close()
   local Result = ConvertResultSet(R)
   return Result
end

function data.DeleteAccessToken(TokenId)
   local DB = data.Connection()
   local SQL = [[DELETE FROM "AccessTokens" WHERE "Id"=]] .. DB:quote(TokenId) 
   DB:execute{sql=SQL}
   DB:close()
end

function data.GetClient()
   local DB = data.Connection()
   local SQL = [[SELECT * FROM Client;]]
   local Result = ConvertResultSet(DB:execute{sql=SQL,live=true})
   DB:close()
   Result[1].ClientUrl = filter.base64.dec(Result[1].ClientUrl)
   return Result[1]
end

function data.SetClient(ClientId, ClientUrl)
   local DB = data.Connection()
   local SQL = [[INSERT OR REPLACE INTO "Client" ("Id", "ClientId", "ClientUrl") VALUES(1, ]] ..
   DB:quote(ClientId) .. [[, ]] .. DB:quote(filter.base64.enc(ClientUrl)) .. [[);]]
   DB:execute{sql=SQL,live=true}
   DB:close()
end

function data.GetClientAccess(WhereKey, WhereVal)
   local DB = data.Connection()
   local SQL = [[SELECT * FROM ClientAccess WHERE ]] .. WhereKey .. [[=]] .. DB:quote(WhereVal) .. [[;]]
   local Result = ConvertResultSet(DB:execute{sql=SQL,live=true})
   DB:close()
   Result[1].TokenEndpoint = filter.base64.dec(Result[1].TokenEndpoint)
   return Result
end

function data.GetLaunch(WhereKey, WhereVal)
   local DB = data.Connection()
   local SQL = [[SELECT LaunchId FROM ClientAccess WHERE ]] .. WhereKey .. [[=]] .. DB:quote(WhereVal) .. [[;]]
   local R = DB:query{sql=SQL}
   DB:close()
   local Result = ConvertResultSet(R)
   return Result
end

function data.InitClientAccessEntry(StateGuid, LaunchId, TokenEndpoint)
   local DB = data.Connection()
   local SQL = [[INSERT OR REPLACE INTO "ClientAccess"("StateGuid", "LaunchId", "TokenEndpoint", "Client") VALUES(]] ..
   DB:quote(StateGuid) .. [[, ]] .. DB:quote(LaunchId) .. [[, ]] .. DB:quote(filter.base64.enc(TokenEndpoint)) .. [[, 1);]]
   DB:execute{sql=SQL,live=true}
   DB:close()
end

function data.updateClientAccessCode(StateGuid, Code)
   local DB = data.Connection()
   local SQL = [[UPDATE "ClientAccess" SET "Code"=]] ..
   DB:quote(Code) .. [[ WHERE "StateGuid"=]] .. DB:quote(StateGuid) .. [[;]]
   DB:execute{sql=SQL,live=true}
   DB:close()
end

function data.clearSearchParamTable()
   local DB = data.Connection()
   local Sql = [[DELETE FROM "SearchParams";]]
   DB:execute{sql=Sql,live=true}
   DB:close()
end

function data.insertSearchParam(ResourceName, SearchParam)
   local DB = data.Connection()
   local Sql = [[INSERT INTO "SearchParams"("Resource", "SearchParam") VALUES(]] ..
      DB:quote(ResourceName) .. [[, ]] .. DB:quote(SearchParam) .. [[);]]
   DB:execute{sql=Sql,live=true}
   DB:close()
end

function data.getSearchParams(ResourceName)
   local DB = data.Connection()
   local Sql = [[SELECT "SearchParam" FROM "SearchParams" WHERE Resource=]] .. DB:quote(ResourceName)
   local Result = DB:query{sql=Sql,live=true}
   DB:close()
   Result = ConvertResultSet(Result)
   if #Result == 1 then
      return json.parse{data=Result[1].SearchParam}
   end
end

-- *** SESSION TOKEN ROUTINES USED FOR THE GUI we have to create Authorization Tokens.

-- We use sessions in the simple GUI to serve up session keys.
function data.IsSessionValid(Session)
   local DB = data.Connection();
   local R = DB:query{sql=[[SELECT * FROM Sessions]]..
      [[ WHERE SessionId = ]]..DB:quote(Session)}
   DB:close()
   if #R == 1 then
      return true, R[1].UserId:S(), tonumber(R[1].Expiry:nodeValue())
   end
end

-- Create a session as used in the database.
function data.CreateSession(SessionId, UserId, ExpiryTime)
   local DB = data.Connection();
   SQL = [[INSERT INTO "Sessions"("SessionId", "UserId", "Expiry") VALUES(]]
   ..DB:quote(SessionId)..", "..DB:quote(UserId)..", "..ExpiryTime..")"
   trace(SQL)
   DB:execute{sql=SQL}
   -- Code to clean out old expired sessions from the session database.
   SQL =[[DELETE FROM "Sessions" WHERE "Expiry" < ]]..os.ts.time()
   DB:execute{sql=SQL}
   DB:close()
end   

-- Delete a session - i.e. logout.
function data.DeleteSession(SessionId)
   local DB = data.Connection()
   local SQL = [[DELETE FROM "Sessions" WHERE "SessionId" = ]]..DB:quote(SessionId)
   trace(SQL)
   DB:execute{sql=SQL}
   DB:close()
end

return data