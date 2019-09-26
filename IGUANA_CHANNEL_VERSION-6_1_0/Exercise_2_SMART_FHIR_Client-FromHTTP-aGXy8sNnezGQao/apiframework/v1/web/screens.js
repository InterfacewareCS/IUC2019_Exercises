if (!api) {
	var api = {};
}

var DesignUrl='https://designer.interfaceware.com/'

api.tokens = function(App) {
   console.log(api.tokens);
   var Model = {};
   Model.Name = App.grammar().Name;
   Model.TestPageUrl = DesignUrl + "#test?ApiId="+App.grammar().ApiId;
   $.get('_listTokens', {}, function(R) {
      if (R.Success) {
         Model.Tokens = R.TokenList;
         
         App.drawMain(Mustache.render(App.templateTable()['/token_list.html'], Model));

         $('#generateToken').click(function() {
            var TokenName = $('#tokenInput').val();
            console.log("Generating token " + TokenName);
            if (!TokenName || TokenName === '') {
               banner.dialog(App, "Enter a name.");
               return
            }
            console.log("Posting _generateToken");
            $.post('_generateToken', {Name : TokenName}, function(R) {
               if (R.Success) {
                  api.tokens(App);
               } else {
                  console.log("Error", R);
                  error.dialog(App, R.Message);
               }
            });
         });

         $('.tokenShowButton').click(function(E) {
            var CurrentRow = $(E.currentTarget).closest('tr');
            $(CurrentRow.children('td.tokenDisplay').children()[1]).toggle();
            $(CurrentRow.children('td.tokenDisplay').children()[1]).children()[0].select()
         });
         
         $('.tokenRemoveButton').click(function(E) {
            console.log("Remove click");
            var CurrentRow = $(E.currentTarget).closest('tr');
            var TokenId = CurrentRow.attr('id');
            console.log("TokenId", TokenId);
            $.post('_removeToken', {TokenId : TokenId}, function(R) {
               if (R.Success) {
                  api.tokens(App);
               }
            });
         });
         
         $("#backToMain").click(function() {
            api.main(App);
         });
      }
   });
}

api.main = function(App) {
   console.log("api.main");
   var Model = {};
   Model.LoggedIn = App.loggedIn();
   
   if ( App.loggedIn() ) {
      $.get('session', {}, function(Response) {
         console.log(Response);
         Model.Sessions = Response.data;
         App.drawMain(Mustache.render(App.templateTable()['/main.html'], Model));

         $(".startSession").on("click", function() {
            var $THIS = $(this);
            var Data = {
               patient : $THIS.attr("id")
            };
            console.log(Data);
            $.post('session/start', Data, function(Response) {
               console.log(Response);
               var Patient = JSON.parse(Response.data.patient);
               fhir.sessionStart(App, Patient);
            });
         });

         $("#generateTokens").click(function() {
            console.log("Calling api.tokens");
            api.tokens(App);
         });

         $("#setClientId").on("click", function() {
            console.log("go client");
            console.log(fhir);
            fhir.clientId(App);
         });

      });
   }
   else {
      App.drawMain(Mustache.render(App.templateTable()['/main.html'], Model));

      $("#generateTokens").click(function() {
         console.log("Calling api.tokens");
         api.tokens(App);
      });

      $("#setClientId").on("click", function() {
         console.log("go client");
         console.log(fhir);
         fhir.clientId(App);
      });

      $("#submitLogin").click(function() {
         user.login(App);
      });

      $(document).keypress(function(e){
         if(e.which == 13){
            $("#submitLogin").click();
         }
      });
   }
     
}