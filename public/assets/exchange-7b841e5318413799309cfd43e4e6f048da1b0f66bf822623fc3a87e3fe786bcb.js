(function() {
  var executeQuery;

  $(function() {
    console.log("DOM is ready");
    return setTimeout(executeQuery, 5000);
  });

  executeQuery = function() {
    console.log("Busca rodada");
    $.get('exchange/order_stats');
    return setTimeout(executeQuery, 6500);
  };

  this.pair = function(string) {
    return $.post("/pair", {
      commit: string
    });
  };

  this.dynamic_form = function(string) {
    return $.post("/order_form_dynamic", {
      commit: string
    });
  };

}).call(this);
