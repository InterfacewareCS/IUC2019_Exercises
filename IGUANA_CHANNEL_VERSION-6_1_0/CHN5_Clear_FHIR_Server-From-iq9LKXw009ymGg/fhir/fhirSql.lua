local azure = require "azure.adTokenAPI" 
local this = {}

function this.initDb(m_Db)

      local Sql = [[CREATE TABLE IF NOT EXISTS Token(TokenVal TEXT PRIMARY KEY, Expiry TEXT)]]
      m_Db:execute{sql=Sql, live=true}

end

function this.insertDb(m_Db)
   local tokenData = azure.getAccessTokenV1Data()
    local Sql = [[INSERT INTO Token(TokenVal, Expiry) VALUES(]] .. 
   m_Db:quote(tokenData.access_token) .. [[, ]] .. 
   m_Db:quote(tokenData.expires_on) .. [[);]]
   m_Db:execute{sql=Sql, live=true}
end

function this.deleteDb(m_Db)
   local Sql = [[DROP TABLE IF EXISTS Token;]]
   m_Db:execute{sql=Sql, live=true}
   local Sql1 = [[CREATE TABLE IF NOT EXISTS Token(TokenVal TEXT PRIMARY KEY, Expiry TEXT)]]
   m_Db:execute{sql=Sql1, live=true}
end

function this.getfromDb(m_Db)
   
   local Sql = [[SELECT * from Token]]
	local result = m_Db:query{sql=Sql, live=true}
   return result
   end
return this 