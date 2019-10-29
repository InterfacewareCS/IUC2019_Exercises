-- The main function is the first function called from Iguana.
-- The Data argument will contain the message to be processed.
function main(Data)

   local BearerAccessToken = "+LxuXTkAllkY0h55MRi3tnkOQcWjmnm4Ykp6x8e1v1w="
   local Url = "http://localhost:6547/iuc/"
   
   local response = net.http.post{
      url=Url.."person", 
      headers={["Authorization"] = "Bearer "..BearerAccessToken}, 
      body=Data,
      live=true
   }
   local Data = json.parse{data=response}   

end