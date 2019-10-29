

var Router = function(){
   var m_Page = {}
   var m_Precheck = null; 
   var m_Default = null;
   var m_IgnoreLastChange = false;
   var m_HashChangeEvent = null;
   
   this.start = function(){
      window.onhashchange = OnHashChange;
      OnHashChange();
   }
   
   this.stop = function(){
      window.onhashchange = null; 
   }
   
   this.route = function(Path, Callback){
      console.log("Set up route:", Path);
      m_Page[Path] = Callback;
   }
   
   this.setDefault = function(Callback){
      m_Default = Callback;  
   }

   this.navigate = function(Path, Change){
      if (document.location.hash !== Path){
         document.location.hash = Path;
         m_IgnoreLastChange = !Change;
      }
   }
   
   this.setPrecheck = function(Callback){
      m_Precheck = Callback;
   }
   
   this.setHashChangeEvent = function(Callback) {
      m_HashChangeEvent = Callback;
   }
   
   function parseQuery(Value){
      //console.log('table.util.parseQuery', Value);
      var Table = {}
      if (!Value){
         return Table;  
      }
      var Parts=Value.split('&');

      for(var i=0; i < Parts.length; i++){
         var Pair = Parts[i].split("=");
         Table[Pair[0]] = Pair[1]
      }
      return Table;
   }

   
   function OnHashChange(){
      console.log("OhHashChange");
      if (m_IgnoreLastChange){
         console.log("We ignore this last change.");
         m_IgnoreLastChange = false;
         return;
      }
      if (m_HashChangeEvent) {
         m_HashChangeEvent();
      }
      var Location = document.location.hash;
      console.log("OnHashChange", Location);
      var Parts = Location.split("?");
      //console.log(Parts);
      var Base = Parts[0].substring(1);
      var Arg 
      if (Parts.length > 1){
         Arg = Parts[1];
      }
      var ArgTable = parseQuery(Arg);
      console.log("OnHashChange", Base, ArgTable);
      if (!m_Page[Base]){
         console.log("No hash function.");
         if (m_Default) {
            m_Default(Base);  
         }
         return;   
      }
      if (m_Precheck){
         m_Precheck(ArgTable, m_Page[Base]);  
         return;
      }
      // no precheck so just call the table.
      m_Page[Base](ArgTable);
   }
}