if (!error){
   var error = {}  
}

error.dialog = function(App, Message){
   var Model = {"Error" : Message};
   var Html = Mustache.render(App.templateTable()["/error/dialog.html"], Model);
   // TODO - should we clear views?
   $('body').append(Html);
   $("div.closeError").click(function(){ 
      $("div.errorPanel").fadeOut(function(){
         $(this).remove()
      }); 
   });
} 