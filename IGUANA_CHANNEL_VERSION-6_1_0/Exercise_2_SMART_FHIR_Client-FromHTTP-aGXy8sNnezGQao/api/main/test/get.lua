-- Call GET /test
--[[ This is a test resource.]]

function Test(Call, App)
   local Result = Call.response()
   
   -- TODO Write code to look at Call data and populate Result
   Result.data.ResponseTest = [[Hi, I'm Iggy."]]
   return Result
end

return Test