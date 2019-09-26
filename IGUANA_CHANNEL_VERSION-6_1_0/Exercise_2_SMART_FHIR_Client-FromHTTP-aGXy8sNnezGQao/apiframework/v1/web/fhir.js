if (!fhir) {
   var fhir = {};
}

fhir.clientId = function(App, Patient) {
   console.log("fhir.clientId");
   var Model = {};
   Model.LoggedIn = App.loggedIn();
   App.drawMain(Mustache.render(App.templateTable()['/templates/app.html'], Model));
	
   $("#goToMain").on("click", function() {
      api.main(App);
   });

   $("#saveClientId").on("click", function() {
      var Data = {
         client_id : $("#ClientId").val(),
         app_location : App.location()
      };

      $.post("_saveClientId", Data, function(Result) {
         console.log(Result);
         api.main(App);
      });
   });
	
}

fhir.sessionStart = function(App, Patient) {
	console.log('fhir.sessionStart');
   console.log(Patient);
   App.drawMain(Mustache.render(App.templateTable()["/fhir/session_start.html"], Patient));
   
   var SearchBase = null;
   var SearchParams = [];
   
   $("#setSearchBase").on("click", function() {
      var Data = { 
         resource_name : $("#SearchBase").val() 
      };
      $.ajax({
         url : "SearchParam", 
         method : "GET",
         data : Data, 
         success : function(R) {
            console.log(R);
            if ( R.data ) {
               SearchBase = $("#SearchBase").val();
               SearchParams = R.data;
            }
         },
         error : function() {
            error.dialog(App, "Resource Entered (" + $("#SearchBase").val() + ") is not in the FHIR server's CapabilityStatement.");
         }
      });
   });
   
   $("#addParam").on("click", function() {
      if ( SearchBase == null ) {
         error.dialog(App, "Set a Search Base");
         return
      }
      var Html = App.templateTable()["/fhir/search_param.html"];
      var Model = { SearchParams : SearchParams };
      $("#searchParamContainer").append(Mustache.render(Html, Model));
      $("param-remove").on("click", function() {
         console.log($(this));
      });
   });
   
   $("#submitQuery").on("click", function(R) {
      var Data = {
         SearchBase : SearchBase,
         Parameters : []
      }
      $(".param").each(function() {
         console.log($(this));
         Data.Parameters.push({ 
            name : $(this).find(".param-name").val(),
            value : $(this).find(".param-val").val()
         });
      });
      $.ajax({
         url : "session/search",
         method : "POST",
         data : JSON.stringify(Data),
         datatType : "application/json",
         success : function(R) {
            console.log(R);
            fhir.bundle(App, JSON.parse(R.data.fResource), Patient);
         },
         error : function(R) {
            console.log(R);
         }
      });
   });
}

fhir.bundle = function(App, Bundle, Patient) {
	console.log('fhir.bundle');
   var Html = prettyPrint(Bundle.entry);
   App.drawMain(Html);
}

fhir.redirect = function(App, Args) {
	console.log("fhir.redirect");
}