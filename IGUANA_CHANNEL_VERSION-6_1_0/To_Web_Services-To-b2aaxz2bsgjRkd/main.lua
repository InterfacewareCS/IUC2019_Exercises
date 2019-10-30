-- In this script, we are building a basic web client.
-- We are going to parse patient demographic info from an incoming HL7 message
-- and pass that data to a web service.


-- Import local module that has mapping details


function main(Data)
   
   
   -- 1. PREPARE OUR REQUEST
   
   -- Parse our incoming HL7 message
   

   -- Handle message types.
   -- Filter out all messages that are NOT ADT
   -- and log the discarded messages


   -- Log all validation errors on incoming message.
   
   
   -- Define the body of our web service request

   
   -- Parse our JSON body to enable mapping

   
   -- Create a function in the mappings.lua local module
   -- to map to the JSON message.
   
   
   
   -- Serialize from Lua table to JSON
   
   
   -- 2. SENDING OUR REQUEST 
   

   -- 3. HANDLING OUR RESPONSE
  
   
   -- Log the response and status code
   
end

   