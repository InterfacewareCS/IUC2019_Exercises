local database = {}

function database.executeSql(sqlScript)
   local Conn = db.connect{api=db.SQLITE, name=iguana.project.files()["other/PatientDataIUC2019.sqlite"],live=true}
   local QueryResult = Conn:execute{sql=sqlScript, live=true}
   Conn:close{}
   return QueryResult
end

return database