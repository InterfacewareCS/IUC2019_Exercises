local JsonUtilities = {}

---------------------------------------------------
---------------------------------------------------
------------- JSON FHIR Object Helpers -----------
---------------------------------------------------
---------------------------------------------------

local function shouldBeRemoved(JsonNode)
   if JsonUtilities.isEmpty(JsonNode) or (JsonUtilities.hasOnlyOne(JsonNode) and JsonNode["resourceType"] ~= nil) then
      -- No children, 
      -- or only child is a constant defining an empty child resource type 
      return true
   end
   return false
end

JsonUtilities.removeEmptyNodes = function(FhirJSON)
   for Key, Value in pairs(FhirJSON) do
      trace(Key, Value)
      if type(Value) == "table" then
         if shouldBeRemoved(Value) then FhirJSON[Key] = nil end 
         if FhirJSON[Key] ~= nil then
            JsonUtilities.removeEmptyNodes(Value)
            if shouldBeRemoved(Value) then FhirJSON[Key] = nil end
         end
      elseif Value == json.NULL then
         FhirJSON[Key] = nil
      elseif type(Value) == "function" then
         FhirJSON[Key] = nil
         elseif Value == '' then
         FhirJSON[Key] = nil
      end
   end
end



---------------------------------------------------
---------------------------------------------------
------------- General JSON Helpers ---------------
---------------------------------------------------
---------------------------------------------------

JsonUtilities.mapSize = function(Map)
   local Size = 0
   for k,v in pairs(Map) do
     Size = Size + 1
   end
   return Size
end

JsonUtilities.isEmpty = function(Map)
   local Size = 0
   for k,v in pairs(Map) do
     return false
   end
   return true
end

JsonUtilities.hasOnlyOne = function(Map)
   local Size = 0
   for k,v in pairs(Map) do
     Size = Size + 1
     if Size == 2 then 
         return false
     end
   end
   return Size == 1
end

return JsonUtilities