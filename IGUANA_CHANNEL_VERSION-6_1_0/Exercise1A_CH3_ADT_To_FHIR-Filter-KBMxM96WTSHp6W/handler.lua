local config = require 'config'
local this = {}


function this.errorHandle(message) --Log error Message to Logs
   iguana.logError("Error, Message not parsed. HL7 message: " .. message)
end

function this.parseDate(date) -- Convert date to proper format
   local d1 = date:sub(1,10)
   local d2 = d1:split('-')
   return d2[1] .. '-' .. d2[2] .. '-' .. d2[3]
   end

function this.parsehl7 (Data) -- Parses Hl7 message to lua table
   return hl7.parse{vmd="hl7.vmd", data = Data}
end
return this