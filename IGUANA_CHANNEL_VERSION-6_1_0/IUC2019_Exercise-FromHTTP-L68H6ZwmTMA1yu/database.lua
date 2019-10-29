
local function Database()
   local DB = db.connect{api=db.SQLITE,  name=iguana.project.guid()}
   return DB   
end

return Database