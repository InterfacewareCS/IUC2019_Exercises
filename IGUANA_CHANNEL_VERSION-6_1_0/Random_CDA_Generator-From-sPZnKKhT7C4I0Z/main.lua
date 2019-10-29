-- This is an example of generating a NIST compliant C32 CDA document
local cda = require 'cda'

local createDoc = require 'createDocument'

-- See http://help.interfaceware.com/v6/generate-a-cda-document
function main()
   
   local Doc = cda.new()
   local CD = Doc.ClinicalDocument   
   
   -- Add header element to CDA document
   createDoc.headElement(CD)
   
   -- Add footer element to CDA document
   createDoc.bodyElement(CD)
  
   trace(Doc)
   queue.push{data=tostring(Doc)}
   
end