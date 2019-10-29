-- The main function is the first function called from Iguana.
-- The Data argument will contain the message to be processed.
function main(Data)

   -- STEP 1: Parse CDA (XML) into an XML node tree
   local C = xml.parse{data=Data}

   -- STEP 2: Create a empty message
   -- TO DO: Change to JSON
   local testTable = {}

   -- STEP 3: Map
   testTable['identifier '] = C.ClinicalDocument.recordTarget.patientRole:child("id", 1).extension:nodeValue()
   testTable['name'] = C.ClinicalDocument.recordTarget.patientRole.patient.name.given:nodeText()..' '
   ..C.ClinicalDocument.recordTarget.patientRole.patient.name.family:nodeText()

   testTable['telecom'] = C.ClinicalDocument.recordTarget.patientRole.telecom.value
   testTable['gender'] = C.ClinicalDocument.recordTarget.patientRole.patient.administrativeGenderCode.code
   testTable['birthDate'] = C.ClinicalDocument.recordTarget.patientRole.patient.birthTime.value
   testTable['address'] = C.ClinicalDocument.recordTarget.patientRole.addr.streetAddressLine:nodeText()
   ..' '..C.ClinicalDocument.recordTarget.patientRole.addr.city:nodeText()
   ..', '..C.ClinicalDocument.recordTarget.patientRole.addr.state:nodeText()
   ..', '..C.ClinicalDocument.recordTarget.patientRole.addr.country:nodeText()
   ..' '..C.ClinicalDocument.recordTarget.patientRole.addr.postalCode:nodeText()

   trace(testTable)

   --STEP 4: TO DO: Push to queue
   local OutMsg = {
      ['identifier'] = testTable["identifier "],
      ['name'] = testTable.name,
      ['address'] = testTable.address,
      ['gender'] = testTable.gender:nodeValue(),
      ['telecom'] = testTable.telecom:nodeValue(),
      ['birthDate'] = testTable.birthDate:nodeValue(),
   }
   
   OutMsg = json.serialize{data=OutMsg}
   
   queue.push{data=OutMsg}

end