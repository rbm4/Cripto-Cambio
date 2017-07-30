(function() {
  $(function() {
    return console.log("DOM is ready");
  });

  $("#buym1").change(function() {
    var comission, current_value, liquido, total;
    console.log("Change rodado");
    comission = $("comission_buy");
    total = $("total_buy");
    liquido = $("liquid_buy");
    $('#buym2').keyup(function() {});
    current_value = $.trim(this.value);
    return comission.html(current_value);
  });

}).call(this);
