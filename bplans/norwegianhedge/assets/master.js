
// Set global options here (StackOverflow: https://goo.gl/XPgaMu)
Chart.defaults.global.defaultFontFamily = "Roboto Mono";
Chart.defaults.global.defaultFontSize = 10;

// Disable tooltips
Chart.defaults.global.tooltips.enabled = false;

// Disable pointers
Chart.defaults.global.elements.point.radius = 0;
Chart.defaults.global.elements.point.hoverRadius = 0;

/* ------------------------------ */

var pieTotalOptions = {
  legend: {
    display: true,
    position: "right"
  },
  title: {
    display: false
  }
}

var pieTotalData = {
  labels: ["Aktiva", "Programvareutvikling", "Infrastruktur", "Lønn", "Annet"],
  datasets: [{
    backgroundColor: [
      "#000000",
      "#0B486B",
      "#327CCB",
      "#7F94B0",
      "#A1BEE6"
    ],
    data: [
      20,
      40,
      20,
      10,
      10
    ]
  }],
};

var ctx = document.getElementById("pieTotal").getContext("2d");
new Chart(ctx, {
  type: 'pie',
  data: pieTotalData,
  options: pieTotalOptions
});

/* ------------------------------ */

var pieCryptosOptions = {
  legend: {
    display: true,
    position: "right"
  },
  title: {
    display: false
  }
}

var pieCryptosData = {
  labels: ["BTC", "XRP", "ETH", "BCH", "XML", "BSV", "USDT", "LTC", "TRX"],
  datasets: [{
    backgroundColor: [
      "#0B486B",
      "#327CCB",
      "#7F94B0",
      "#A1BEE6",
      "#00ADEF",
      "#D2D2D2",
      "#000000",
      "#CCCCCC",
      "#DDDDDD"
    ],
    data: [
      20,
      10,
      10,
      10,
      10,
      10,
      10,
      10,
      10
    ]
  }],
  
};

var ctx = document.getElementById("pieCryptos").getContext("2d");
new Chart(ctx, {
  type: 'pie',
  data: pieCryptosData,
  options: pieCryptosOptions
});

/* ------------------------------ */

var pieStocksOptions = {
  legend: {
    display: true,
    position: "right"
  },
  title: {
    display: false
  }
}

var pieStocksData = {
  labels: ["TSLA", "AMZN", "BABA", "NVDA", "AMD", "CUR"],
  datasets: [{
    backgroundColor: [
      "#0B486B",
      "#327CCB",
      "#7F94B0",
      "#A1BEE6",
      "#00ADEF",
      "#D2D2D2"
    ],
    data: [
      1.6,
      1.6,
      1.6,
      1.6,
      1.6,
      1.6
    ]
  }],
};

var ctx = document.getElementById("pieStocks").getContext("2d");
new Chart(ctx, {
  type: 'pie',
  data: pieStocksData,
  options: pieStocksOptions
});

