-- The main function is the first function called from Iguana.
function main()

   ------------------------------------------------------------------------
   -- Basic Authentication ------------------------------------------------
   ------------------------------------------------------------------------

   local User = "admin"
   local Password = "password"
   local BasicAccessToken = filter.base64.enc(User..":"..Password)

   local LogResults, Code = net.http.get{
      url = 'http://localhost:6767/api_query',
      headers = {["Authorization"] = "Basic "..BasicAccessToken},
      parameters = {
         limit = 50,
         type = 'message',
         deleted = 'false'
      }, live=true
   }
   local Data = xml.parse{data=LogResults}

   -- OR...

   local LogResults, code = net.http.get{
      url = 'http://localhost:6767/api_query',
      auth = {username="admin", password="password"},
      parameters = {
         limit = 50,
         type = 'message',
         deleted = 'false'
      }, live=true
   }
   local Data = xml.parse{data=LogResults}

   ------------------------------------------------------------------------   
   -- API Key Authentication ----------------------------------------------
   ------------------------------------------------------------------------

   ------------------------------------------------------------------------   
   -- Exercise 1 ----------------------------------------------------------
   -- Use the generated API token to make an authenticated request --------
   ------------------------------------------------------------------------   

   -- Add in API token
   local BearerAccessToken = "+LxuXTkAllkY0h55MRi3tnkOQcWjmnm4Ykp6x8e1v1w="
   -- Ensure the Url is correct
   local Url = "http://localhost:6547/iuc/"

   -- Add in the following HTTP request parameter:
   --   Limit = 10
   local response = net.http.get{
      url=Url.."people", 
      headers={["Authorization"] = "Bearer "..BearerAccessToken}, 
      parameters={["Limit"] = 10}, 
      live=true
   }
   -- Observe response
   local Data = json.parse{data=response}   

   ------------------------------------------------------------------------   
   -- Exercise 2 ----------------------------------------------------------
   -- Use the API response from Exercise 1 to GET a person's data ---------
   ------------------------------------------------------------------------    

   -- Add in the following HTTP request parameter:
   --   identifier = <person identifer>
   local response = net.http.get{
      url=Url.."person", 
      headers={["Authorization"] = "Bearer "..BearerAccessToken}, 
      parameters={["identifier"] = ""}, 
      live=true
   }
   local Data = json.parse{data=response}

   ------------------------------------------------------------------------   
   -- Exercise 3 ----------------------------------------------------------
   -- Create a new person record on the backend database ------------------
   ------------------------------------------------------------------------    

   -- Build the Person data object
   local Person = {
      ['identifier']='938234',
      ['name']='Jim',
      ['address']='Houston, Texas',
      ['gender']='04/10/2010',
      ['telecom']='9056782743',
      ['birthDate']='04/10/2010'
   }

   -- Serialize the Lua table to JSON
   Person = json.serialize{data=Person}

   -- Add in the JSON string as the body of the POST request
   local response = net.http.post{
      url=Url.."person", 
      headers={["Authorization"] = "Bearer "..BearerAccessToken}, 
      body=Person,
      live=true
   }
   local Data = json.parse{data=response}   

   -- Try and get the person from the API server using the identifier
   local response = net.http.get{
      url=Url.."person", 
      headers={["Authorization"] = "Bearer "..BearerAccessToken}, 
      parameters={["identifier"] = "938234"}, 
      live=true
   }
   local Data = json.parse{data=response}

end