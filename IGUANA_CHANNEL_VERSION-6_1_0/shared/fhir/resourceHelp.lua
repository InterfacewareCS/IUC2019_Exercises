-- ************************************************** --
-- FHIRhelp
--  Provide translator help for FHIR resources
--
-- Trevor
-- ************************************************** --

local function GetElementKeys(ElementId)
   local Keys = ElementId:split('.')
	table.remove(Keys, 1) -- remove the first, as it is the parent
   return Keys
end

local function GenerateHelp(Profile)
   local HelpTable = {}
   HelpTable.Title = Profile.id
   HelpTable.ParameterTable = true
   HelpTable.SeeAlso = {}
   HelpTable.SeeAlso[1] = {['Title']="HL7 Reference", ["Link"]=Profile.url}
   HelpTable.Parameters = {}
   for i=1,#Profile.snapshot.element do
      local Element = Profile.snapshot.element[i]
      local Key = GetElementKeys(Element.id)[1]
      if Key then
         table.insert(HelpTable.Parameters, {[Key]={["Desc"]=Element.short}})
      end
   end
   return HelpTable
end

local function GenerateXTypeHelp(ElementDef)
   local HelpTable = {}
   HelpTable.Title = ElementDef.id
   HelpTable.ParameterTable = true
   HelpTable.Parameters = {}
   for i=1,#ElementDef.type do
      table.insert(HelpTable.Parameters, {[ElementDef.type[i].code]={['Desc']="Set as " .. ElementDef.type[i].code}})
   end
   return HelpTable
end

local FHIRhelp = {}

FHIRhelp.setWithPRofile = function(FunctionHandle, Profile)
   help.set{input_function=FunctionHandle, help_data=GenerateHelp(Profile)}
end

FHIRhelp.setXType = function(FunctionHandle, ElementDef)
   help.set{input_function=FunctionHandle, help_data=GenerateXTypeHelp(ElementDef)}
end

return FHIRhelp