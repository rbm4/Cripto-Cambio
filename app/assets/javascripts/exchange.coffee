# Place all the behaviors and hooks related to the matching controller here.
# All this logic will automatically be available in application.js.
# You can use CoffeeScript in this file: http://coffeescript.org/

  

$ ->
  console.log("DOM is ready")
  
$("#buym1").change ->
    console.log("Change rodado")
    comission = $("comission_buy")
    total = $("total_buy")
    liquido = $("liquid_buy")
    $('#buym2').keyup ->
    current_value = $.trim @value
    comission.html(current_value)
    
    
    
    
    
    
    
    