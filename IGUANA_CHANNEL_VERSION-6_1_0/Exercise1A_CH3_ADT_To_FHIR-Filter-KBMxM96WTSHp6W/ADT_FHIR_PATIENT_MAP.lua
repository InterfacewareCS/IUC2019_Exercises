local d = require 'dateparse'
local h = require 'handler'
local this = {}

function this.map (hl7, FHIR)
   --Identifier
   FHIR.id = hl7.PID[3][1][1]:nodeValue()
   FHIR.identifier.use = ''
   FHIR.identifier.value               = hl7.PID[3][1][1]:nodeValue()
   --resourceType
   FHIR.resourceType                   = 'Patient'
   --Active
   FHIR.active                         = true
      
   --Name
   FHIR.name.use                       = 'official'
   FHIR.name.family                    = hl7.PID[5][1][1][1]:nodeValue()
   FHIR.name.given                     = hl7.PID[5][1][2]:nodeValue()

   --telecom
   FHIR.telecom.use                    = 'home'
   FHIR.telecom.value                  = hl7.PID[13][1][1]:nodeValue()
  
   --Gender
   FHIR.gender                         = hl7.PID[8]:nodeValue()
   
   --birthdate
   FHIR.birthDate                      = h.parseDate(hl7.PID[7]:nodeValue():D())
   
   FHIR.deceasedBoolean = false        -- Currently Hardcoded. It is hl7.PID[30]
   
   --address
   FHIR.address.city                   = hl7.PID[11][1][3]:nodeValue()
   FHIR.address.state                  = hl7.PID[11][1][4]:nodeValue()
   FHIR.address.postalCode             = hl7.PID[11][1][5]:nodeValue()
   FHIR.address.line                   = hl7.PID[11][1][1][1]:nodeValue()
   
   --marital status
   FHIR.maritalStatus.text             = hl7.PID[16][2]:nodeValue()
   
   --Photo
   FHIR.photo.id                       = hl7.OBX[1][5][1][1]:nodeValue()
   
   --contact
   FHIR.contact.relationship.text      = hl7.NK1[1][3][1]:nodeValue()
   FHIR.contact.name.given             = hl7.NK1[1][2][1][2]:nodeValue()
   FHIR.contact.name.family            = hl7.NK1[1][2][1][1][1]:nodeValue()
   FHIR.contact.telecom.use            = ''
   FHIR.contact.telecom.value          = hl7.NK1[1][5][1][1]:nodeValue()
   FHIR.contact.address.city           = hl7.NK1[1][4][1][3]:nodeValue()
   FHIR.contact.address.state          = hl7.NK1[1][4][1][4]:nodeValue()
   FHIR.contact.address.postalCode     = hl7.NK1[1][4][1][5]:nodeValue()
   FHIR.contact.address.line           = hl7.NK1[1][4][1][1][1]:nodeValue()
   FHIR.contact.gender                 = hl7.NK1[1][15]:nodeValue()
   FHIR.contact.organization.reference = 'http://someserver/some-path-to-rganization'
   FHIR.contact.period.start           = FHIR.birthDate
   
   --language
   FHIR.communication.language.text    = hl7.PID[15][2]:nodeValue()
   FHIR.communication.preferred        = hl7.PID[15][2]:nodeValue()
   FHIR.link.other.reference           = '' --N/A
   FHIR.link.type                      = '' --N/A
end
return this