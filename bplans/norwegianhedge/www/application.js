$(document).ready(function() {

  // Kjør kode kun på forsiden

  if($('#btc').length) {
    var fiatCurrency = "NOK",
      conversionObj;
  
    function getConversionRate() {
      return $.ajax({
        dataType: "json",
      
        // Use reverse proxy due to lack of CORS (http://enable-cors.org/)
      
        // https://github.com/Rob--W/cors-anywhere
      
        // url: "https://cors.riksmynt.no/localbitcoins.com/bitcoinaverage/ticker-all-currencies/",
        url: "https://cors-anywhere.herokuapp.com/localbitcoins.com/bitcoinaverage/ticker-all-currencies/",
        success: function(data) {
     
          // Parse JSON for rates
          
          rate = data[fiatCurrency].rates.last;
        }
      });
    }
  
    // Initialize rate, then call conversion for initial display
  
    getConversionRate().then(bitcoinToFiat);
  
    function fiatToBitcoin() {
      var number = Number($("#fiat").val());
      $("#btc").val((number / rate).toFixed(4));
    };
  
    function bitcoinToFiat() {
      var number = Number($("#btc").val());
      $("#fiat").val((number * rate).toFixed(2));
    }
  
    $('input').keyup(function() {
      if ($(this).is('input#btc')) {
        bitcoinToFiat();
      } else if ($(this).is('input#fiat')) {
        fiatToBitcoin();
      }
    });
  
    $('input').click(function() {
      $(this).select();
    });
  
    // Copy fiat to HTML
  
    $('label[for="fiat"]').html(fiatCurrency);
  }
});
