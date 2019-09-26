if (!ajax){
   var ajax = {}  
}

ajax.registerErrorHandler = function(App){
   console.log("Register error handler.");
   $(document).ajaxError(function(event, Info, ajaxSettings, thrownError){
      if(settings.suppressErrors) {
         return;
      }
      console.log("Ajax error encountered.");
      console.log(thrownError);
      console.log(Info);
      console.log(event);
      console.log(ajaxSettings);
      var R = Info.responseJSON;
      if (R && R.Message) {
         error.dialog(App, R.message + " Please check your network connection?");
      } else {
         error.dialog(App, "Error trying to connect to server.  Please check your network connection?"); 
      }
   });
   
   $(document).ajaxComplete(function(event, Info, ajaxSettings){
      var R = Info.responseJSON;
      if (!R.Success && R.Message === "Invalid session"){
         user.logout(App);
      }
   }); 
}