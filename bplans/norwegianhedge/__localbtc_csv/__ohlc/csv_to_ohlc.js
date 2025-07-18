
// CSV format: Unix time,price (FIAT),amount traded (BTC)

function convertToOHLC(rawData) {

  // Bitcoinchart's data is without headers, so add them here

  var headers = ["date","price","amountTradedBtc"];

  // Turn CSV into array

  var data = d3.csvParse(headers + "\n" + rawData)

  // Sort chronologically, needed for open/close later on

  data.sort((a, b) => d3.ascending(a.date, b.date));
  
  var result = [];

  // Convert milliseconds to date strings

  var format = d3.timeFormat("%Y-%m-%d");
  data.forEach(d => d.date = format(new Date(d.date * 1000)));

  // Create an array with all the different days

  var allDates = [...new Set(data.map(d => d.date))];

  // Populate each day with our new OHLC data

  allDates.forEach(d => {
    var tempObject = {};
    var filteredData = data.filter(e => e.date === d);
    
    tempObject.date = d;
    tempObject.open = filteredData[0].price;
    tempObject.high = d3.max(filteredData, e => e.price);
    tempObject.low = d3.min(filteredData, e => e.price);
    tempObject.close = filteredData[filteredData.length - 1].price;
    tempObject.amountTradedBtc = filteredData[0].amountTradedBtc;
 
    // Save the result
    
    result.push(tempObject);
  })
  
  // And return it
  
  return result
}

// Convert to OHLC and then CSV

// New CSV format: date,open,high,low,close,amount traded (BTC)

var allTradesEverOHLC = d3.csvFormat(convertToOHLC(allTradesEver));

// console.log(allTradesEverOHLC);
$('.new_ohlc').text(allTradesEverOHLC);
$('.original_csv').text(allTradesEver);

$('h1:nth-of-type(1) span').append(allTradesEverOHLC.length);
$('h1:nth-of-type(2) span').append(allTradesEver.length);

