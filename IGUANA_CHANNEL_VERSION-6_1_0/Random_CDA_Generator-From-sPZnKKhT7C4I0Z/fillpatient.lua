local data = {}

data.Sex = {'M', 'F'}

data.Race = {'AI', 'EU', 'Mixed', 'Martian', 'Unknown'}
-- Street

data.Street = {'Delphi Cres.', 'Miller Lane', 'Yonge St.', 'Main Rd.'}

-- City and Country
data.Locations = { {'Chicago', 'IL'}, {'Miami', 'FL'}, {'ST. LOUIS', 'MO'}, {'LA', 'CA'} }

-- Zip
data.LastNames = {'Muir','Jonas','Smith','Johnson', 'Brown', 'Davis', 'WHITE'}
data.MaleNames = {'San','Shawn','Sam','Thomas'}
data.FemaleNames = {'Monica','Charlotte','Harper'}

local addElement = node.addElement

local function rand(In, Max, Size)
   local Result = tostring((In + math.random(Max)) % Max)
   if '0' == Result then
      Result = '1'
   end
   
   while Size > Result:len() do
      Result = '0'..Result
   end
   return Result
end

local function ranChoose(T)
   return T[math.random(#T)]
end

local function ranAcctNo()
   return 'c-'..math.random(999)..'-'..math.random(999)
end

local function ranSSNNo()
   return '111-'..math.random(99)..'-'..math.random(9999)
end

local function ranLocation()
   local R = ranChoose(data.Locations)
   return R[1], R[2]
end

local function ranNameAndSex()
   local sex, firstname
   if math.random(2) == 1 then
      sex = cda.codeset.sex.Male
      firstname = ranChoose(data.MaleNames)
   else   
      sex = cda.codeset.sex.Female
      firstname = ranChoose(data.FemaleNames)      
   end
   return sex, firstname
end

local function ranDate()
   local T = os.date('*t')
  
   local newDate = '19'..rand(T.year,99,2)..
   rand(T.month,12,2)..
   rand(T.day,29,2)
   
   return newDate
end

local function ranLastName() return ranChoose(data.LastNames) end

function FillPatient(RT)
   local function FillGuardian(G)
      cda.code.add{target=G, element='code', system=cda.codeset.cat["HL7 Role Class"],
         value=cda.codeset.personalRelationshipRole.Parent, lookup=cda.codeset.personalRelationshipRole.reverse}
      cda.demographic.address.add{target=G, use=cda.codeset.address.Home, 
         street= math.random(999)..' '..ranChoose(data.Street), city='Beaverton', state='OR', zip='97867', country='US'}
      cda.demographic.phone.add{target=G, phone='(816)276-6909', use=cda.codeset.address.Home}
      local GP = addElement(G, 'guardianPerson')
      cda.demographic.name.add{target=GP, given='Ralph', family='Jones'}
      
      return G
   end
   
   local function FillBirthPlace(B)
      local P = addElement(B, 'place')
      cda.demographic.address.add{target=P, city='Beaverton', state='OR', zip='97867', country='US'}  
      return B
   end
   
   local function FillLanguageCommunication(L)
      cda.code.simple.add{target=L, element='languageCode', value=cda.codeset.language['English - US']}
      cda.code.add{target=L, element='modeCode', system=cda.codeset.cat["LanguageAbilityMode"],
         value=cda.codeset.proficiencyLevel["Good"], lookup=cda.codeset.proficiencyLevel.reverse}
      cda.value.add{target=L, element='preferenceInd', datatype='BL', value='true'}
      return L
   end
   
   local function FillProviderOrganization(O)
      cda.id.add{target=O, id_type=cda.codeset.cat["National Provider Identifier"]}
      cda.demographic.name.simple.add{target=O, name='Community Health and Hospitals'}
      cda.demographic.phone.add{target=O, phone='(555)555-5000', use=cda.codeset.address.Work}
      cda.demographic.address.add{target=O, use=cda.codeset.address.Work, 
         street='1001 Village Avenue', city='Beaverton', state='OR', zip='99123', country='US'}  
      
      return O
   end
   
   local PR = addElement(RT, 'patientRole')
   
   -- Add random Id
   cda.id.add{target=PR, value= ranAcctNo(), id_type='2.16.840.1.113883.4.6'} -- dummy OID change or map value
   
   -- Add SSN
   cda.id.add{target=PR, value=ranSSNNo(), id_type=cda.codeset.cat.SSN}
   
   --Add Address
   local c, s = ranLocation()
   cda.demographic.address.add{target=PR, use=cda.codeset.address.Home, street= math.random(999)..' '..ranChoose(data.Street), 
      city= c, state= s, zip= math.random(99999), country='US'} 
   
   --Telecome
   
   cda.demographic.phone.add{target=PR, phone='(816)'..math.random(999)..'-'..math.random(9999), use=cda.codeset.address.Home}  
   local P = addElement(PR, 'patient')
   
   local s,fn = ranNameAndSex()
   -- Name
   cda.demographic.name.add{target=P, given= fn, nickname= '', family= ranLastName(), use=cda.codeset.nameUses.Legal}
  
   -- Gender
   cda.code.add{target=P, element='administrativeGenderCode', system=cda.codeset.cat["HL7 AdministrativeGender"], 
      value=s, lookup=cda.codeset.sex.reverse}
   
   --Birth Date
   cda.time.add{target=P, element='birthTime', time=ranDate()}  
   
   cda.code.add{target=P, element='maritalStatusCode', system=cda.codeset.cat["HL7 Marital status"],
      value=cda.codeset.marriage.Married, lookup=cda.codeset.marriage.reverse}
   cda.code.add{target=P, element='religiousAffiliationCode', system=cda.codeset.cat.ReligiousAffiliation,
      value=cda.codeset.religion.Atheism, lookup=cda.codeset.religion.reverse}
   cda.code.add{target=P, element='raceCode', system=cda.codeset.cat["HL7 Race and Ethnicity"],
      value=cda.codeset.race.White, lookup=cda.codeset.race.reverse}
   cda.code.add{target=P, element='ethnicGroupCode', system=cda.codeset.cat["HL7 Race and Ethnicity"], 
      value=cda.codeset.ethnicGroup["Not Hispanic or Latino"], 
      lookup=cda.codeset.ethnicGroup.reverse}

   local G = addElement(P, 'guardian')
   FillGuardian(G)  
   local BP = addElement(P, 'birthplace')
   FillBirthPlace(BP)
   local LC = addElement(P, 'languageCommunication')
   FillLanguageCommunication(LC)
   local PO = addElement(PR, 'providerOrganization')
   FillProviderOrganization(PO)
   
   return RT
end
