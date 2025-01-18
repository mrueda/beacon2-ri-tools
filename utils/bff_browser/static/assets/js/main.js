/*
Button Actions
*/
 $(document).ready(function()  {
     $('#start-using-btn').click(function()  {
         $('#mtdna-hero-unit').hide('slow');
         $('#web-form').show('slow');
    });
});
 $(document).ready(function()  {
     $('#start-using-nav').click(function()  {
         $('#mtdna-hero-unit').hide('slow');
         $('#web-form').show('slow');
    });
});
 $(document).ready(function()  {
     $('#submit-btn').click(function()  {
         $('#web-form').hide('2');
         $('#mtdna-home').hide('2');
    });
});
$(document).ready(function()  {
     $('#go-back').click(function()  {
       history.back();
    });
});
$(document).ready(function()  {
     $('#go-back-two').click(function()  {
       history.go(-2);
    });
});
/*
Misc
*/
$(document).ready(function() { $("input").not("#start-using-btn").jqBootstrapValidation({preventSubmit: false}); } );
/*
Tabs. Note that if we don add class .nav-tab we can-t click on href
*/
$('#tab-summary .nav-tab').click(function (e) {
  e.preventDefault();
  $(this).tab('show');
})
$('#tab-report .nav-tab').click(function (e) {
  e.preventDefault();
  $(this).tab('show');
})
/*
Brute force to disable radio
$("input[type=radio]").attr('disabled', true);
*/
/*
Function to go directly to the form from non-home pages
*/
function start_using()
{
   $(document).ready(function(){
         $('#mtdna-hero-unit').hide('slow');
         $('#web-form').show('slow');

    });
   return false;
}
