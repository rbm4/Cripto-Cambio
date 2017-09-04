(function() {
  var formdinamic;

  formdinamic = function() {
    console.log("chamado formulario dinamico");
    return $.get('exchange/form');
  };

}).call(this);
