local GetSessionKey = function()
   return iguana.project.guid() .. 'Session'
end

return GetSessionKey