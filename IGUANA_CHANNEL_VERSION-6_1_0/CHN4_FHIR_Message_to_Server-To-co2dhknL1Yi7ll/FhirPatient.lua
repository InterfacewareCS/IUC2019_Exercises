local FhirPatient = {}

FhirPatient.json = [[
{
   "active": false,
   "telecom": {
      "resourceType": "ContactPoint",
      "value": "289-961-2837",
      "system": "phone"
   },
   "deceasedboolean": false,
   "contact": {
      "telecom": {
         "resourceType": "ContactPoint",
         "value": "123-456-789",
         "system": "phone"
      },
      "relationship": {
         "coding": [
            {
               "code": "Friend",
               "system": "http://hl7.org/fhir/patient-contact-relationship"
            }
         ],
         "text": "Friend"
      },
      "address": {
         "postalCode": "Y8D6U9",
         "text": "456 Fakes Cres. Fakington, ON Canada Y8D6U9",
         "state": "ON",
         "resourceType": "Address",
         "city": "Fakington",
         "country": "Canada",
         "line": [
            "456 Fakes Cres."
         ]
      },
      "name": {
         "resourceType": "HumanName",
         "family": "Brown",
         "text": "Connor Brown",
         "given": "Connor"
      }
   },
   "resourceType": "Patient",
   "birthDate": "1982-02-02",
   "gender": "male",
   "communication": {
      "language": {
         "coding": [
            {
               "code": "EN",
               "system": "http://tools.ietf.org/html/bcp47"
            }
         ],
         "text": "EN"
      }
   },
   "name": {
      "resourceType": "HumanName",
      "family": "Kadri",
      "text": "Nazem Kadri",
      "given": "Nazem"
   },
   "address": {
      "postalCode": "L5L4I9",
      "text": "8912 Fake St. Fakeington, ON Canada L5L4I9",
      "state": "ON",
      "resourceType": "Address",
      "city": "Fakeington",
      "country": "Canada",
      "line": [
         "8912 Fake St."
      ]
   },
   "id": "1"
}
]]
FhirPatient.json2 = [[
{
   "photo": {
      "id": "102"
   },
   "active": true,
   "telecom": {
      "value": "1185438871",
      "use": ""
   },
   "contact": {
      "telecom": {
         "value": "",
         "use": ""
      },
      "relationship": {
         "text": "Second Cousin"
      },
      "address": {
         "postalCode": "",
         "state": "",
         "line": "",
         "city": ""
      },
      "period": {
         "start": ""
      },
      "gender": "",
      "organization": {
         "reference": ""
      },
      "name": {
         "given": "Gary",
         "family": "Smith"
      }
   },
   "birthDate": "10-Feb-1998",
   "deceasedBoolean": false,
   "identifier": {
      "value": "4525285",
      "use": ""
   },
   "link": {
      "type": "",
      "other": {
         "reference": ""
      }
   },
   "gender": "F",
   "generalPractitioner": {
      "reference": ""
   },
   "communication": {
      "language": {
         "text": ""
      },
      "preferred": ""
   },
   "maritalStatus": {
      "text": ""
   },
   "name": {
      "given": "Tracy",
      "family": "Smith",
      "use": ""
   },
   "address": {
      "postalCode": "51460",
      "state": "MO",
      "line": "86 Yonge St.",
      "city": "ST. LOUIS"
   }
}
]]



FhirPatient.xml = [[
<active value="false"></active>
<name>
   <text value="William Nylander"></text>
   <family value="Nylander"></family>
   <given value="William"></given>
</name>
<telecom>
   <system value="phone"></system>
   <value value="289-753-7856"></value>
</telecom>
<gender value="M"></gender>
<birthDate value="22/12/1994"></birthDate>
<deceased value="false"></deceased>
<address>
   <text value="567 Wrong Ave. Fakeington ON, Canada A4L4I9"></text>
   <line value="567 Wrong Ave."></line>
   <city value="Fakeington"></city>
   <state value="ON,"></state>
   <postalCode value="A4L4I9"></postalCode>
   <country value="Canada"></country>
</address>
<contact>
   <relationship>
      <coding>
         <system value="http://hl7.org/fhir/patient-contact-relationship"></system>
         <code value="Uncle"></code>
      </coding>
      <text value="Uncle"></text
   </relationship>
   <name>
      <text value="Kasperi Kapanen"></text>
      <family value="Kapanen"></family>
      <given value="Kasperi"></given>
   </name>
   <telecom>
   <system value="phone"></system>
   <value value="123-456-7891"></value>
   </telecom>
   <address>
      <text value="789 Maple St. Fakington ON, Canada Y9D6W9"></text>
      <line value="789 Maple St."></line>
      <city value="Fakingto"></city>
      <state value="ON,"></state>
      <postalCode value="Y9D6W9"></postalCode>
      <country value="Canada"></country>
   </address>
</contact>
<communication>
   <language>
      <coding>
         <system value="http://tools.ietf.org/html/bcp47"></system>
         <code value="EN"></code>
      </coding>
      <text value="EN"></text>
   </language>
</communication>
]]

return FhirPatient