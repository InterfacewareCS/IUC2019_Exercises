require 'fillheader'
require 'fillpatient'
require 'cda.xml'
require 'cda.null'
require 'cda.codeset'
require 'fillstakeholders'
require 'fillserviceevent'
require 'filladvanceddirectives'
require 'fillAllergies'
require 'fillencounters'
require 'fillproblemlist'
require 'fillprocedures'
require 'fillvitalsigns'
local addElement = node.addElement
local createDoc = {}

function createDoc.headElement(CD)
    -- CDA Header 
   FillHeader(CD)
   local RT = addElement(CD, 'recordTarget')
   FillPatient(RT)
   local A = addElement(CD, 'author')
   FillAuthor(A)
   --[[local DE = addElement(CD, 'dataEnterer')
   FillDataEnterer(DE) 
   local I = addElement(CD, 'informant')
   FillInformant1(I)
   I = addElement(CD, 'informant')
   FillInformant2(I)--]]
   local C = addElement(CD, 'custodian')
   FillCustodian(C)
   local IR = addElement(CD, 'informationRecipient')
   FillInformationRecipient(IR)
   local LA = addElement(CD, 'legalAuthenticator')
   FillLegalAuthenticator(LA)
   local AU = addElement(CD, 'authenticator')
   FillAuthenticator(AU)
   --[[local D = addElement(CD, 'documentationOf')
   FillServiceEvent(D)--]]
   
end


function createDoc.bodyElement(CD)
    -- CDA Body
   local Body = addElement(CD, 'component')
   local SB = addElement(Body, 'structuredBody')
   local COM = addElement(SB, 'component')
   FillAdvancedDirectives(COM)
  --[[ COM = addElement(SB, 'component')   
   FillAllergies(COM)
   COM = addElement(SB, 'component')--]]
   FillEncounters(COM)    
   COM = addElement(SB, 'component')
    --[[FillProblemList(COM)   
   COM = addElement(SB, 'component')
   FillProcedures(COM)--]]
   COM = addElement(SB, 'component')
   FillVitalSigns(COM)
end


return createDoc