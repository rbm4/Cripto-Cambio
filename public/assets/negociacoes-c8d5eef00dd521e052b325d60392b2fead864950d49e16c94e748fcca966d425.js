(function() {
  var formdinamic;

  formdinamic = function() {
    console.log("chamado formulario dinamico");
    return $.get('exchange/form');
  };

  $teste(function() {
    return console.log("DOM is ready");
  });

}).call(this);
