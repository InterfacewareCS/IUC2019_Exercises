local PersonTemplate = {
   ['identifier']='',
   ['name']='',
   ['address']='',
   ['gender']='',
   ['telecom']='',
   ['birthDate']=''
}

function main(Data)

   local InBoundMsg, MessageType = hl7.parse{vmd="example/demo.vmd",data=Data}
   
   local Person = PersonTemplate
   
   Person.address = InBoundMsg.PID[11][1][1][1]:nodeValue()
   Person.birthDate = InBoundMsg.PID[7][1]:nodeValue()
   Person.gender = InBoundMsg.PID[8]:nodeValue()
   Person.identifier = util.guid(128)
   Person.name = InBoundMsg.PID[5][1][2]:nodeValue()
   Person.telecom = InBoundMsg.PID[13][1][1]:nodeValue()
   
   queue.push{data=json.serialize{data=Person}}

end