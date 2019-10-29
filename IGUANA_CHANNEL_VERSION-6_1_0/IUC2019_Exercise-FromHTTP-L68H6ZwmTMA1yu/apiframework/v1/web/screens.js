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
   Model.Name = App.grammar().Name;
   Model.Description = App.grammar().Description;
   Model.DesignerLink = DesignUrl + "#overview?ApiId="+App.grammar().ApiId;
   Model.LoggedIn = App.loggedIn();
   App.drawMain(Mustache.render(App.templateTable()['/main.html'], Model));
   
   $("#generateTokens").click(function() {
      console.log("Calling api.tokens");
      api.tokens(App);
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

api.start = function(App) {
   console.log('api.start');
   $.get("_grammar", function(R) {
	   console.log("Got grammar", R);
      if (R.Success) {
         App.setGrammar(R.Grammar);
         api.main(App);
      } else {
         console.log("Error occurred getting grammar.");
         error.dialog(App, R.Message);         
      }
   });
}