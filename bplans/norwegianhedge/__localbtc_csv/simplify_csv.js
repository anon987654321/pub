
// Original CSV format: Unix time,price (FIAT),amount traded (BTC)
  
function simplifyCsv(dataSet) {

  // Set time in milliseconds to a month

  intervalLength = 2628000000;

  lastPrice = 0;
  index = 0;
  
  monotizedDataSet = []
    
  while(index < dataSet.length) {

    // Reset value for this interval

    amountTradedBtc = 0;
    priceFiat = 0;
    count = 0;
    
    unixTime = dataSet[index][0] + intervalLength;

    // Get sums for this interval

    while(dataSet[index][0] < unixTime) {
      amountTradedBtc += dataSet[index][2];
      priceFiat += dataSet[index][1];
      count++;
      index++;

      if(index >= dataSet.length) {
        break;
      }
    }

    // Get average price

    priceFiat = count > 0 ? priceFiat / count : lastPrice;
    lastPrice = priceFiat;

    // Add new row to monotized array

    monotizedDataSet.push({
      "Unix time": unixTime,
      "price (FIAT)": priceFiat,

      // Gets converted from BTC in `allTradesEverFinal`

      "amount traded (FIAT)": amountTradedBtc
    });
  }
}

function unixTimeToMilliseconds(time) {
  var newTime = Math.floor(time * 1000);
  
  return newTime
}

// Parse multi-line CSV string into a 2D array
// https://github.com/evanplaice/jquery-csv

var allTradesEverArrayTemp = $.csv.toArrays(allTradesEver);

// jquery-csv's arrays are made up of strings, but we need them to be numbers

// Trim whitespace and convert to `Number()`

var allTradesEverFinal = allTradesEverArrayTemp.map(row => row.map(el => Number(el.trim())))

  // Chart.js requires time in milliseconds

  .map(row => [unixTimeToMilliseconds(row[0]), row[1], row[2]])

  // We want amount traded in FIAT, so multiply bitcoins with price

  .map(row => [row[0], row[1], row[1] * row[2]]);

// Reduce trade times to same-sized intervals

simplifyCsv(allTradesEverFinal);

$(".new_csv").text($.csv.fromObjects(monotizedDataSet));

// ----------
// $(".original_csv").text(allTradesEver);

