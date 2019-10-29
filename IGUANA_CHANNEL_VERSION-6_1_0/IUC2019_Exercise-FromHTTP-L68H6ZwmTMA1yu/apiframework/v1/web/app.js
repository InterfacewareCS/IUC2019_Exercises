
var Application = function() {
   var m_Templates = {};
   var m_UserName = null;
   var m_Router = new Router();
   var m_Grammar = {};
   var m_SessionKey = null;
	
   this.loggedIn = function() {
      return m_UserName !== null;
   }
   
   this.setUserName = function(V){
      m_UserName = V;  
   }
   
   this.grammar = function() {
	   return m_Grammar;
   }
   
   this.setGrammar = function(G) {
      m_Grammar = G;
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
   
    
   this.drawMain = function(Html){
      console.log("Drawing in main view");
      var Model = {UserName : m_UserName}
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
   Router.route("",         function(){ api.start(App);  });
    
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
