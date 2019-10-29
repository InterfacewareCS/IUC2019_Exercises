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
]]
}

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