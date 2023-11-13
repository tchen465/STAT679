function D2Str(dateStr) {
    let [year, month] = dateStr.split(' ');
    return new Date(year, new Date(`${month} 1, ${year}`).getMonth());
}

function parse(data) {
  return {
    date: D2Str(data.date),
    calfresh: +data.calfresh,
    county: data.county
  }
}


function visualize(data) {
  let scales = make_scales(data);
  let groupedData = d3.group(data, d => d.county);
  
  groupedData.forEach((value, key) => {
    draw_line(value, scales, key);
  });
  add_axes(scales);
  //draw_choropleth(data,scales);
}

function draw_line(data, scales, county) {
  path_generator = d3.line()
    .x(d => scales.x(d.date))
    .y(d => scales.y(d.calfresh));

  d3.select("#line")
    .selectAll("path." + county)
    .data([data]).enter()
    .append("path")
    .attr("class", county)
    .attr("d", path_generator);
}

function add_axes(scales) {
  let x_axis = d3.axisBottom()
        .scale(scales.x)
        //.tickFormat(d3.timeFormat("%Y")),
      y_axis = d3.axisLeft()
        .scale(scales.y);

  d3.select("#axes")
    .append("g")
    .attrs({
      id: "x_axis",
      transform: `translate(0,${height - margins.bottom})`
    })
    .call(x_axis);

  d3.select("#axes")
    .append("g")
    .attrs({
      id: "y_axis",
      transform: `translate(${margins.left}, 0)`
    })
    .call(y_axis)
}

function make_scales(data) {
  let y_max = d3.max(data.map(d => d.calfresh)),
      x_extent = d3.extent(data.map(d => d.date));

  return {
    x: d3.scaleTime()
         .domain(x_extent)
         .range([margins.left, 0.5*width - margins.right]),
    y: d3.scaleLinear()
         .domain([0, y_max])
         .range([height - margins.bottom, 0.5*height - margins.top])
  }
}

function draw_choropleth(data){
  
  let projection = d3.geoMercator()
  .fitsize([width,height,data]);
  let path = d3.geoPath()
  .projection(projection);
  
  let colorScale = d3.scaleThreshold()
  .domain([0,10000,50000,100000])
  .range(d3.schemeBlues[4]);
  
  d3.select("#choropleth")
  .selectAll("path")
  .data(data.calfresh).enter()
  .append("path")
  .attrs({
    d:path
  })
}

let width = 1000,
    height = 500,
    margins = {top: 50, bottom: 50, left: 50, right: 50}

d3.csv("calfresh-small.csv", parse)
  .then(visualize)