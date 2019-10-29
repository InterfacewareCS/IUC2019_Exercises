-- One of the most challenging areas of computer science is dates.
-- The API framework deliberately keeps this open by putting date/time validation
-- in this one file.

-- Out of the box we assume dates are formatted in Unix Epoch Time - the number of seconds
-- since 1st January 1970.

local ValidationError = "needs to be in unix epoch time.  Number of seconds since 1st January 1970."

local function ValidateDateTime(Instance, Key, Cast)
   local Value = Instance[Key]
   trace(Value)
   if Value == json.NULL then
      return true
   end
   if Cast and type(Value) == "string" then
      local CastValue = tonumber(Value)
      if CastValue == nil then
         return false, ValidationError
      end
      Instance[Key] = CastValue
      return true
   end
   if type(Value) == 'userdata' then
      local V = Value:nodeValue()
      if tostring(tonumber(V)) ~= V then
         return false, ValidationError
      end
   elseif type(Value) ~= "number" then
      return  false, ValidationError
   end
   return true
end

return ValidateDateTime