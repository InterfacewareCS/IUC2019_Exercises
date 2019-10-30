local map = {}

-- Define the outgoing message format. In this case, it's JSON.
function map.template() 
   local JSONTemplate = [[{"patient": {
   "id": "",
   "name_first": "",
   "name_last": "",
   "city": "",
   "state": "",
   "zip": "",
   "phone_home": "",
   "phone_work": "",
   "race": "", 
   "gender": "", 
   "ssn": "" 
}
}]]
   
   return JSONTemplate
end

-- Map the incoming data to the outgoing message.

return map