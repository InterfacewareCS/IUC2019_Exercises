-- ************************************************** --
-- FHIRresource
--  Generate a template for a FHIR resource as a Lua
--  table filled with json.NULL values.
--
-- Trevor
-- ************************************************** --

local FHIRhelp = require 'fhir.resourceHelp'

local StopPoints = {
	['Extension']={['extension']=true},
   ['Identifier']={['assigner']=true},
   ['Reference']={['identifier']=true}
}

local function GetElementKeys(ElementId)
   local Keys = ElementId:split('.')
	local Parent = table.remove(Keys, 1) -- remove the first, as it is the parent
   return Keys, Parent
end

local function GetElementTypeAndId(DB, Element)
   local Id
   if Element.type and Element.type[1] and Element.type[1].code then
      Id = Element.type[1].code
   elseif Element.type and Element.type[1] and Element.type[1]["_code"] then
      local Keys = GetElementKeys(Element.id)
      Id = Keys[1]
   end
   return DB:listResourceTypes(Id)[1] or error("Unknown Type" .. Id), Id
end

local function FHIRresource(DB, ResourceName)
   local R = {}
   local Profile = DB:get(ResourceName)
   local Snapshot = Profile.snapshot.element
   local i = 1
   local this, last
   for i=1,#Snapshot do
      local Element = Snapshot[i]
      local Keys, Parent = GetElementKeys(Element.id)
      
      if #Keys > 0 and Keys[1] ~= 'contained' then
         
         local Target = R
         if Target and #Keys > 1 then
            while #Keys > 1 do
               Target[Keys[1]] = Target[Keys[1]] or {}
               Target = Target[Keys[1]]
               table.remove(Keys,1)
            end
         end
         
         local ElementType, ElementTypeId = GetElementTypeAndId(DB, Element)
         
         if Keys[1]:find("%[x]") then
            Target[Keys[1]] = {}
            Target[Keys[1]].set = function(Self, Args)
               local ChangeXTo = next(Args)
               Target[Keys[1]:gsub("%[x]", ChangeXTo:capitalize())] = json.NULL
               Target[Keys[1]] = nil
            end
            if iguana.isTest() then
               FHIRhelp.setXType(Target[Keys[1]].set, Element)
            end
         elseif ElementType == 'primitive-type' then
            Target[Keys[1]] = json.NULL
         elseif ElementTypeId == 'BackboneElement' then
            Target[Keys[1]] = {}
         elseif ElementType == 'complex-type' then
            local Stop = (StopPoints[Parent] and StopPoints[Parent][Keys[1]]) or Keys[1] == 'extension'
            if not Stop then
               Target[Keys[1]] = FHIRresource(DB, ElementTypeId)
            end
         end
      end
   end
   
   return R
end

return FHIRresource