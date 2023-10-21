# Shiny App for PS2 II b)
# Load necessary libraries
library(shiny)
library(ggplot2)
library(plotly)
library(sf)
library(dplyr)
library(crosstalk)

# Define the UI
ui <- fluidPage(
  
  titlePanel("Interactive Analysis of Power Plants"),
  
  fluidRow(
    plotlyOutput("histogram", height = 300),
    plotlyOutput("map", height = 400)
  )
)

# Define the server logic
server <- function(input, output) {
  
  # Read and preprocess data
  power_plants <- read_sf("https://raw.githubusercontent.com/krisrs1128/stat992_f23/main/exercises/ps2/power_plants.geojson") %>%
    mutate(
      longitude = st_coordinates(geometry)[, 1],
      latitude = st_coordinates(geometry)[, 2],
      logPower = log(1 + capacity_mw)
    )
  
  # Reactive expression for brushed data
  brushed_data <- reactive({
    brushed_points <- event_data("plotly_brushing", source = "brushSource")
    if (is.null(brushed_points)) {
      return(power_plants)
    } else {
      x_min <- min(brushed_points$x)
      x_max <- max(brushed_points$x)
      
      selected_data <- power_plants %>%
        filter(logPower >= x_min & logPower <= x_max)
      if(nrow(selected_data) == 0) {
        return(power_plants)
      }
      return(selected_data)
    }
  })
  
  # Stacked Histogram
  output$histogram <- renderPlotly({
    hist_plot <- ggplot(data = power_plants, aes(x = logPower, fill = primary_fuel)) +
      geom_histogram(position = "stack", bins = 30) +
      labs(title = "Distribution of log(1+Power) by Fuel",
           x = "log(1+Power)", 
           y = "Count of Plants")
    
    p <- ggplotly(hist_plot, dynamicTicks = TRUE, source = "brushSource") %>%
      layout(dragmode = "select")
    p$x$data[[1]]$hoverinfo <- "none" 
    p
  })
  
  # Map of Power Plants
  output$map <- renderPlotly({
    brushed_df <- brushed_data()
    map_plot <- ggplot(data = brushed_df, aes(x = longitude, y = latitude)) +
      geom_point(aes(color = primary_fuel, size = capacity_mw), alpha = 0.6) +
      scale_size_continuous(name = "Generation Capacity (MW)") +
      labs(title = "Power Plants in the Upper Midwest",
           x = "Longitude", y = "Latitude", color = "Primary Fuel") +
      theme_minimal()
    
    ggplotly(map_plot, tooltip = NULL, dynamicTicks = TRUE)
  })
  
}

# Run the Shiny app
shinyApp(ui = ui, server = server)

