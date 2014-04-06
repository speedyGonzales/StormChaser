//create guages for individual cyclones



google.load('visualization', '1', {packages:['gauge']});
// console.log("Hello")
google.setOnLoadCallback($.get("/cyclones/" + gon["cyclones"]["id"] + "/histweather", function(data) {setTimeout(function(){drawChart(data)},500);}, "json"));
// No idea why it's gon["cyclones"]["id"] instead of gon["cyclones"][0]["id"]


drawChart = function(histdata) {
  // console.log("ehh")
  window.x = histdata;
  // console.log("In the drawChart")
  var pressure = google.visualization.arrayToDataTable([
    ['Label', 'Value'],
    ['Pressure', histdata.currently.pressure],
  ]);
  // console.log(pressure)

  var temp = google.visualization.arrayToDataTable([
    ['Label', 'Value'],
    ['Temp', histdata.currently.temperature],
  ]);

  var wind_speed = google.visualization.arrayToDataTable([
    ['Label', 'Value'],
    ['Wind Speed', histdata.currently.windSpeed]
  ]);

  var pressure_options = {
    width: 400, height: 120,
    max: 1050, min: 900,
    redFrom: 1000, redTo: 1050,
    yellowFrom:975, yellowTo: 9999,
    minorTicks: 5
  };

  var temp_options = {
    width: 400, height: 120,
    max: 110, min:0,
    redFrom: 90, redTo: 110,
    yellowFrom:75, yellowTo: 89,
    minorTicks: 5
  };

  var wind_speed_options = {
    width: 400, height: 120,
    max: 70, min:0,
    redFrom: 40, redTo: 70,
    yellowFrom:20, yellowTo: 39,
    minorTicks: 5
  };

  var chart1 = new google.visualization.Gauge(document.getElementById('chart_div1'));
  chart1.draw(pressure, pressure_options);

  var chart2 = new google.visualization.Gauge(document.getElementById('chart_div2'));
  chart2.draw(temp, temp_options);

  var chart3 = new google.visualization.Gauge(document.getElementById('chart_div3'));
  chart3.draw(wind_speed, wind_speed_options);
}


