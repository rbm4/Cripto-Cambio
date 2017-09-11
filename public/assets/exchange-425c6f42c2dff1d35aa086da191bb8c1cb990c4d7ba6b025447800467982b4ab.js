(function() {
  var executeQuery, pair;

  $(function() {
    console.log("DOM is ready");
    return setTimeout(executeQuery, 5000);
  });

  executeQuery = function() {
    console.log("Busca rodada");
    $.get('exchange/order_stats');
    return setTimeout(executeQuery, 6500);
  };

  pair = function(string) {
    return $.post("/pair", {
      commit: string
    });
  };

}).call(this);
