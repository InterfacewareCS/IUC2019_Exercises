// Login and logout calls
// Creates and destroys a session cookie 

if (!user){
   var user = {}
}

user.login=function(App){
   console.log("user.login");
   var Data = {}
   Data.Name = $("input#name").val();
   Data.Password = $("input#password").val();
	
   $.get("_login", Data, function(R){
      console.log(R);
      if (!R.Success){
         $(".error").show().html(R.Message);   
      } else {
         console.log("Current hash: ", document.location.hash);
         // store the session ID
         $(".error").hide();
         document.cookie = R.SessionKey+"=; expires=Thu, 01 Jan 1970 00:00:00 UTC; path=/;";
         document.cookie = R.SessionKey+"="+R.SessionId;
         console.log("Session = ", R.SessionId);
         App.setSessionKey(R.SessionKey);
         App.setUserName(R.Name);
         App.router().start();  // start routing 
      }
   });
}

user.logout=function(App){
   console.log("user.logout");
   $.get("_logout", {}, function(R){
      App.router().stop();
      App.setUserName(null);
      document.cookie = App.sessionKey() + "=; expires=Thu, 01 Jan 1970 00:00:00 UTC; path=/;";     
      api.start(App);
   });
}

user.createLogout = function(App){
   $('#logout').click(function() { 
      user.logout(App); 
   });
}
