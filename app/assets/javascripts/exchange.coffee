# Place all the behaviors and hooks related to the matching controller here.
# All this logic will automatically be available in application.js.
# You can use CoffeeScript in this file: http://coffeescript.org/

  

$ ->
  console.log("DOM is ready")
  setTimeout(executeQuery, 5000)
  
executeQuery = () ->
    console.log("Busca rodada")
    $.get 'exchange/order_stats'
    setTimeout(executeQuery, 6500)
    
    
@pair = (string) ->
 $.post( "/pair", { commit: string } );