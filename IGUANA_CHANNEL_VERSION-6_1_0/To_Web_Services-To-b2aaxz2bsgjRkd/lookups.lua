local parseCsv = require 'csv'


iguana.workingDir()
   
   -- Now open it for reading
   local F = io.open("race_lookup.txt", "r")
   local Content = F:read("*a")
   -- Closing files is a good idea especially
   -- with windows.
   F:close()
   trace(Content)
   
   local raceLookup = parseCsv(Content)
   
   raceMap = {}
   
   for i=1, #raceLookup do 
   trace(raceLookup[i])
      
      for j=1, #raceLookup[i] do 
      
      raceMap[raceLookup[i][1]] = raceLookup[i][2]
      end
   
   
   end
   trace(raceMap)