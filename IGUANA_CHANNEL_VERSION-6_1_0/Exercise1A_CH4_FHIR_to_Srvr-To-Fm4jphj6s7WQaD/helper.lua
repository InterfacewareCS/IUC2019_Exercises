local fSql = require "fhir.fhirSql"

local this = {}


function this.generateToken (m_Db)
   -- 1. init db
   fSql.initDb(m_Db)
   -- 2. get data
   local Result = fSql.getfromDb(m_Db)
   -- 3. Populate db if empty
   if #Result == 0 then 
      fSql.insertDb(m_Db)
   end
   -- 4. delete token if expiry time has passed and request/return new one
   Result = fSql.getfromDb(m_Db)
   if tonumber(Result[1].Expiry:nodeValue()) < os.ts.time() then
      trace('Token Expired')
      fSql.deleteDb(m_Db)
      fSql.insertDb(m_Db)
      Result = fSql.getfromDb(m_Db)
      return 'Authorization: Bearer ' .. Result[1].TokenVal
   end
   -- 5. return token if not expired
   trace('Token Good')
   return 'Authorization: Bearer ' .. Result[1].TokenVal

end

function this.formatURL (data)
   local base = data.SearchBase .. [[?]]
   local fBase
   for i=1,#data.Parameters do
      base = base .. data.Parameters[i].name .. [[=]] .. data.Parameters[i].value .. [[&]]
   end
   if base:sub(base:len()) == "&" then 
      fBase = base:sub(1, base:len()-1)
   end
   return fBase
end

--parseEnvVar
function this.AZURE_FHIR_URL()
  local file = io.open(iguana.workingDir() .. 'IguanaEnv.txt', "r")
  if file then
        local sLine = file:read()
	     file:close()
        var = sLine:split('=')
      
        return var[2]
  end
  return nil
end

return this