
var bitcoinPriceGrowthOptions = {
  legend: {
    display: false
  },
  tooltips: {
    display: false
  },
  title: {
    display: true,
    fontFamily: "SourceSansPro",
    text: "Bitcoins prisvekst"
  },
  scales: {
    xAxes: [{
      type: "time",
      time: {
        displayFormats: {

          // TODO: These shouldn't be necessary

          hour: "MMM YYYY",
          quarter: "MMM YYYY",
          year: "MMM YYYY"
        }
      },
      ticks: {
        // Make labels vertical
        // https://stackoverflow.com/questions/28031873/make-x-label-horizontal-in-chartjs
        minRotation: 90
      },
      gridLines: {
        display: false
      },
    }],
    yAxes: [{
      gridLines: {
        // Remove the outer border along the Y-axis
        drawBorder: false
      },
      // Format value into currency
      // https://stackoverflow.com/questions/36918887/chart-js-2-0-formatting-y-axis-with-currency-and-thousands-separator
      ticks: {
        // Return an empty string to draw the tick line but hide the tick label
        // Return `null` or `undefined` to hide the tick line entirely
        userCallback: function(value, index, values) {
          // Convert the number to a string and split the string every 3 charaters from the end
          value = value.toString();
          value = value.split(/(?=(?:...)*$)/);

          // Convert the array to a string and format the output
          value = value.join(' ');
          return value + 'kr';
        },
        padding: 5
      }
    }]
  }
}

var bitcoinPriceGrowthData = {
  labels: [
1365735484000, 1368634636000, 1371914704000, 1374612220000, 1377277149000, 1380123905000, 1382768107000, 1385397581000, 1388049859000, 1390733940000, 1393362858000, 1396024300000, 1398653535000, 1401287351000, 1403919876000, 1406570614000, 1409223584000, 1411873845000, 1414522723000, 1417158050000, 1419786847000, 1422415159000, 1425052587000, 1427681786000, 1430323780000, 1432953772000, 1435606160000, 1438240092000, 1440873869000, 1443510201000, 1446146062000, 1448775310000, 1451427778000, 1454059900000, 1456689227000, 1459321271000, 1461950266000, 1464584821000, 1467212822000, 1469841815000, 1472491093000, 1475119346000, 1477754939000, 1480385215000, 1483022061000, 1485650209000, 1488313867000, 1490942133000, 1493575118000, 1496204046000, 1498832159000, 1501461590000

],
  datasets: [{
    label: false,
    fill: false,
    backgroundColor: "#0000FF",
    borderColor: "#0000FF",
    borderWidth: 1,
    data: [

1091.956111111111, 708.4899999999997, 710.2200000000001, 564.1253448275862, 652.3219565217391, 828.4441791044774, 971.8674647887326, 2508.083387096774, 5941.691632653058, 5615.748651162783, 4938.008097826086, 3919.2266883116877, 2986.949210526314, 2980.5919780219765, 3869.4800581395325, 3975.417283236992, 3520.251592920353, 3069.618325991189, 2539.8183552631567, 2541.9972909699, 2675.910584615385, 2129.5970359281437, 1910.095824468085, 2290.2883211678845, 1964.492023460412, 1901.34489010989, 1969.983693931399, 2374.816297169811, 2251.951533018868, 2062.34112195122, 2251.23803611738, 3168.2577924528287, 3737.3866938110714, 3842.8775939849606, 3569.4677631578925, 3669.6376070901024, 3654.4657812500036, 3817.621241743727, 5393.182918410049, 5801.191664698942, 5011.544755168667, 5124.336079766538, 5379.955330700886, 6323.6217770326875, 7000.676744574287, 8123.058149405758, 8993.195157318749, 10332.621694695963, 10726.105144804076, 17125.269430535118, 22781.296610243044, 20884.849372093064

],
  }]
}

var ctx = document.getElementById("bitcoin_price_growth").getContext("2d");
new Chart(ctx, {
  type: "line",
  data: bitcoinPriceGrowthData,
  options: bitcoinPriceGrowthOptions
});


/* ------------------------------ */


var localbitcoinsTradeVolumeOptions = {
  legend: {
    display: true,
    position: "right",
    labels: {
      fontFamily: "SourceSansPro",
      boxWidth: 10,
      boxHeight: 3
    }
  },
  tooltips: {
    display: false
  },
  title: {
    display: true,
    fontFamily: "SourceSansPro",
    text: "Handelsvolum på LocalBitcoins"
  },
  scales: {
    xAxes: [{
      type: "time",
      time: {
        displayFormats: {

          // TODO: These shouldn't be necessary

          hour: "MMM YYYY",
          quarter: "MMM YYYY",
          year: "MMM YYYY"
        }
      },
      ticks: {
        // Make labels vertical
        // https://stackoverflow.com/questions/28031873/make-x-label-horizontal-in-chartjs
        minRotation: 90
      },
      gridLines: {
        display: false
      },
    }],
    yAxes: [{
      gridLines: {
        // Remove the outer border along the Y-axis
        drawBorder: false
      },
      // Format value into currency
      // https://stackoverflow.com/questions/36918887/chart-js-2-0-formatting-y-axis-with-currency-and-thousands-separator
      ticks: {
        // Return an empty string to draw the tick line but hide the tick label
        // Return `null` or `undefined` to hide the tick line entirely
        userCallback: function(value, index, values) {
          // Convert the number to a string and split the string every 3 charaters from the end
          value = value.toString();
          value = value.split(/(?=(?:...)*$)/);

          // Convert the array to a string and format the output
          value = value.join(' ');
          return value + 'kr';
        },
        padding: 5
      }
    }]
  }
}

var localbitcoinsTradeVolumeData = {
  labels: [

1365735484000, 1368634636000, 1371914704000, 1374612220000, 1377277149000, 1380123905000, 1382768107000, 1385397581000, 1388049859000, 1390733940000, 1393362858000, 1396024300000, 1398653535000, 1401287351000, 1403919876000, 1406570614000, 1409223584000, 1411873845000, 1414522723000, 1417158050000, 1419786847000, 1422415159000, 1425052587000, 1427681786000, 1430323780000, 1432953772000, 1435606160000, 1438240092000, 1440873869000, 1443510201000, 1446146062000, 1448775310000, 1451427778000, 1454059900000, 1456689227000, 1459321271000, 1461950266000, 1464584821000, 1467212822000, 1469841815000, 1472491093000, 1475119346000, 1477754939000, 1480385215000, 1483022061000, 1485650209000, 1488313867000, 1490942133000, 1493575118000, 1496204046000, 1498832159000, 1501461590000

],
  datasets: [{
    label: "Norge",
    fill: false,
    backgroundColor: "#0000FF",
    borderColor: "#0000FF",
    borderWidth: 1,
    data: [
41068.254583, 48942.89774899999, 43125.99202899999, 78450.25629499998, 167211.06102699996, 238641.55456089252, 224120.28022500002, 806372.1480217618, 1065934.56144453, 598696.9965540005, 358825.340541, 342044.225004631, 401972.0651226271, 363368.60524100024, 467892.96191199956, 513037.749472, 581711.3581499996, 521637.6874790005, 614904.543032, 700769.623388, 711903.9250659999, 592270.2120159997, 839841.3612500004, 603265.3638769999, 752953.1491729997, 852487.323263, 835918.1383830006, 1185559.0644529997, 1214092.445610001, 1087272.5112319996, 994129.3943129999, 1377885.0552189997, 1839196.4434759982, 1798313.883331001, 1418590.0568830005, 2145762.1589220017, 2804144.6486579995, 2271553.933364003, 3670819.7952999985, 2716241.4261980033, 2658844.509556001, 2929291.141664004, 3192416.4118040004, 4521233.318402997, 4277706.100480004, 4490864.211673003, 5594627.190463009, 6422092.229555034, 4915919.730355327, 13741905.030339917, 18642975.081101745, 4772654.748607969

    ]
  }, {
    label: "Sverige",
    fill: false,
    backgroundColor: "#00FF00",
    borderColor: "#00FF00",
    borderWidth: 1,
    data: [

82564.83612100001, 49284.82705299999, 18412.436022, 66977.802168, 142966.43906599996, 216003.9020110001, 287903.3572512501, 225097.30789620194, 624138.0080269729, 882640.6179201952, 674372.6059919999, 616204.6489700975, 746802.2759450122, 651972.3798059766, 1188419.5010499994, 1250151.8421269986, 1397296.436612, 1795741.7110289985, 2231387.969827, 1930777.4559970014, 2038737.0704610012, 2120502.712100999, 3516411.894269008, 3934774.800161008, 3257059.852675003, 4376713.296242998, 4297800.895941005, 4953147.0732870065, 5122682.610251004, 4791845.354096003, 5535329.222667005, 6693662.295602007, 6440470.458097, 6024226.667474994, 7843101.279148001, 7790584.218019997, 8187033.53541999, 9096684.01238401, 9849888.572774995, 9182104.327535994, 8579352.928158997, 9434266.012698991, 9588680.892489998, 9726540.241325976, 10046692.566887025, 13279588.52455898, 10510849.802101925, 12825185.548120847, 12442558.306701936, 13517984.23160304, 20670431.88064469, 13501647.849977164


    ]
  }]
};

var ctx = document.getElementById("localbitcoins_trade_volume").getContext("2d");
new Chart(ctx, {
  type: "line",
  data: localbitcoinsTradeVolumeData,
  options: localbitcoinsTradeVolumeOptions
});



/* ------------------------------ */

// https://blog.graphiq.com/finding-the-right-color-palettes-for-data-visualizations-fcd4e707a283

var totalProfitEstimateData = {
  labels: ["2018", "2019", "2020", "2021"],
  datasets: [{
    label: 'LocalBitcoins',
    fill: false,
    backgroundColor: "#333333",
    borderColor: "#333333",
    borderWidth: 1,
    data: [
      5762,
      42204,
      231840,
      1132062
    ]
  },{
    label: 'Holding BTC',
    fill: false,
    backgroundColor: "#0288d1",
    borderColor: "#0288d1",
    borderWidth: 1,
    data: [
      1970379,
      3021860,
      3855020,
      4566986
    ]
  }, {
    label: 'Holding LSK',
    fill: false,
    backgroundColor: "#b3e5fc",
    borderColor: "#b3e5fc",
    borderWidth: 1,
    data: [
      2128009,
      3263608,
      4163422,
      4932344
    ]
  }]
};


var totalProfitEstimateOptions = {
  legend: {
    display: true,
    position: "right",
    labels: {
      fontFamily: "SourceSansPro",
      boxWidth: 10,
      boxHeight: 3
    }
  },
  tooltips: {
    display: false
  },
  title: {
    display: true,
    fontFamily: "SourceSansPro",
    text: "Totalt forventet profitt"
  },
  scales: {
    xAxes: [{
      stacked: true,
      time: {
        displayFormats: {

          // TODO: These shouldn't be necessary

          hour: "MMM YYYY",
          quarter: "MMM YYYY",
          year: "MMM YYYY"
        }
      },
      ticks: {
        // Make labels vertical
        // https://stackoverflow.com/questions/28031873/make-x-label-horizontal-in-chartjs
        minRotation: 90
      },
      gridLines: {
        display: false
      },
    }],
    yAxes: [{
      stacked: true,
      gridLines: {
        // Remove the outer border along the Y-axis
        drawBorder: false
      },
      // Format value into currency
      // https://stackoverflow.com/questions/36918887/chart-js-2-0-formatting-y-axis-with-currency-and-thousands-separator
      ticks: {
        // Return an empty string to draw the tick line but hide the tick label
        // Return `null` or `undefined` to hide the tick line entirely
        userCallback: function(value, index, values) {
          // Convert the number to a string and split the string every 3 charaters from the end
          value = value.toString();
          value = value.split(/(?=(?:...)*$)/);

          // Convert the array to a string and format the output
          value = value.join(' ');
          return value + 'kr';
        },
        padding: 5
      }
    }]
  }
}



var ctx = document.getElementById("total_profit_estimate").getContext("2d");
new Chart(ctx, {
  type: 'bar',
  data: totalProfitEstimateData,
  options: totalProfitEstimateOptions
});







////////!!!!!!!


var holdingProfitEstimateData = {
  labels: ["2018", "2019", "2020", "2021"],
  datasets: [{
    label: 'Holding BTC',
    fill: false,
    backgroundColor: "#0288d1",
    borderColor: "#0288d1",
    borderWidth: 1,
    data: [
      1970379,
      3021860,
      3855020,
      4566986
    ]
  }, {
    label: 'Holding LSK',
    fill: false,
    backgroundColor: "#b3e5fc",
    borderColor: "#b3e5fc",
    borderWidth: 1,
    data: [
      2128009,
      3263608,
      4163422,
      4932344
    ]
  }]
};


var holdingProfitEstimateOptions = {
  legend: {
    display: true,
    position: "right",
    labels: {
      fontFamily: "SourceSansPro",
      boxWidth: 10,
      boxHeight: 3
    }
  },
  tooltips: {
    display: false
  },
  title: {
    display: true,
    fontFamily: "SourceSansPro",
    text: "Forventet profitt ved holding"
  },
  scales: {
    xAxes: [{
      stacked: true,
      time: {
        displayFormats: {

          // TODO: These shouldn't be necessary

          hour: "MMM YYYY",
          quarter: "MMM YYYY",
          year: "MMM YYYY"
        }
      },
      ticks: {
        // Make labels vertical
        // https://stackoverflow.com/questions/28031873/make-x-label-horizontal-in-chartjs
        minRotation: 90
      },
      gridLines: {
        display: false
      },
    }],
    yAxes: [{
      stacked: true,
      gridLines: {
        // Remove the outer border along the Y-axis
        drawBorder: false
      },
      // Format value into currency
      // https://stackoverflow.com/questions/36918887/chart-js-2-0-formatting-y-axis-with-currency-and-thousands-separator
      ticks: {
        // Return an empty string to draw the tick line but hide the tick label
        // Return `null` or `undefined` to hide the tick line entirely
        userCallback: function(value, index, values) {
          // Convert the number to a string and split the string every 3 charaters from the end
          value = value.toString();
          value = value.split(/(?=(?:...)*$)/);

          // Convert the array to a string and format the output
          value = value.join(' ');
          return value + 'kr';
        },
        padding: 5
      }
    }]
  }
}



var ctx = document.getElementById("holding_profit_estimate").getContext("2d");
new Chart(ctx, {
  type: 'bar',
  data: holdingProfitEstimateData,
  options: holdingProfitEstimateOptions
});

///////////////

var localbitcoinsProfitEstimateData = {
  labels: ["2018", "2019", "2020", "2021"],
  datasets: [{
    fill: false,
    backgroundColor: "#0288d1",
    borderColor: "#0288d1",
    borderWidth: 1,
    data: [
      5762,
      42204,
      231840,
      1132062
    ]
  }]
};


var localbitcoinsProfitEstimateOptions = {
  legend: {
    display: false,
    position: "right",
    labels: {
      fontFamily: "SourceSansPro",
      boxWidth: 10,
      boxHeight: 3
    }
  },
  tooltips: {
    display: false
  },
  title: {
    display: true,
    fontFamily: "SourceSansPro",
    text: "Forventet profitt på LocalBitcoins"
  },
  scales: {
    xAxes: [{
      stacked: true,
      time: {
        displayFormats: {

          // TODO: These shouldn't be necessary

          hour: "MMM YYYY",
          quarter: "MMM YYYY",
          year: "MMM YYYY"
        }
      },
      ticks: {
        // Make labels vertical
        // https://stackoverflow.com/questions/28031873/make-x-label-horizontal-in-chartjs
        minRotation: 90
      },
      gridLines: {
        display: false
      },
    }],
    yAxes: [{
      stacked: true,
      gridLines: {
        // Remove the outer border along the Y-axis
        drawBorder: false
      },
      // Format value into currency
      // https://stackoverflow.com/questions/36918887/chart-js-2-0-formatting-y-axis-with-currency-and-thousands-separator
      ticks: {
        // Return an empty string to draw the tick line but hide the tick label
        // Return `null` or `undefined` to hide the tick line entirely
        userCallback: function(value, index, values) {
          // Convert the number to a string and split the string every 3 charaters from the end
          value = value.toString();
          value = value.split(/(?=(?:...)*$)/);

          // Convert the array to a string and format the output
          value = value.join(' ');
          return value + 'kr';
        },
        padding: 5
      }
    }]
  }
}



var ctx = document.getElementById("localbitcoins_profit_estimate").getContext("2d");
new Chart(ctx, {
  type: 'bar',
  data: localbitcoinsProfitEstimateData,
  options: localbitcoinsProfitEstimateOptions
});








