
var Application = function() {
   var m_Templates = {};
   var m_UserName = null;
   var m_FhirServers = {};
   var m_Router = new Router();
   var m_SessionKey = null;
   var m_Location = window.location;
	
   this.loggedIn = function() {
      return m_UserName !== null;
   }
   
   this.setUserName = function(V){
      m_UserName = V;  
   }
   
   this.addFhirServer = function(FhirServerId, FhirServerName) {
      m_FhirServers.push();
   }
   
   this.setFhirServers = function(FhirServers) {
      m_FhirServers = FhirServers;
   }
   
   this.router = function() {
      return m_Router;  
   }
   
   this.setTemplateTable = function (V){
      m_Templates = V;
   }
   
   this.templateTable = function(){
     return m_Templates; 
   }
  
   this.setSessionKey = function(Name){
      m_SessionKey = Name;
   }
   
   this.sessionKey = function(){
      return m_SessionKey;   
   }
   
   this.location = function() {
	   return m_Location.href;
   }
   
   this.drawMain = function(Html){
      console.log("Drawing in main view");
      var Model = {
         UserName : m_UserName,
         FhirServers : m_FhirServers
      };
      var MenuHtml = Mustache.render(this.templateTable()["/frame.html"], Model);
      $('body').html(MenuHtml);
      if (m_UserName) {
         user.createLogout(this);
      }
      $('#content-target').html(Html);
   }
}

function CheckSession(App){
   console.log('Checking if Logged in');
   $.get("_checkSession", {}, function(R){
      console.log("checkSession");
      console.log(R);
      if (R.Success){
         // if it's not a success it will be picked up by our global AJAX handler.
         console.log(R.Data.Name);
         App.setUserName(R.Data.Name); 
         App.router().start();
      }
   });
}

function SetupRoutes(App){
   var Router = App.router();
   Router.route("",              function(){ api.main(App);  });
   Router.route("app",           function(){ api.main(App);  });
   Router.route("hspc/redirect/view", function(Args){ fhir.redirect(App, Args); });
   
   Router.setDefault( function(Page) { error.dialog(App, "Page " + Page + " is unknown."); });  
   Router.setHashChangeEvent(App.setSessionTimerRefresh);
}

$().ready(function() {
   console.log('Ready event');
   window.App = new Application();
   ajax.registerErrorHandler(window.App);
   SetupRoutes(App);
   $.get('_loadTemplates',function(Response){ 
       App.setTemplateTable(Response); 
       CheckSession(App); 
   });
});
