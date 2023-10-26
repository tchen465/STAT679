# Shiny App for PS2 II b)

# Load libraries
library(shiny)
library(ggplot2)
library(plotly)
library(sf)
library(dplyr)
library(crosstalk)

power_plants <- read_sf("https://raw.githubusercontent.com/krisrs1128/stat992_f23/main/exercises/ps2/power_plants.geojson") %>%
  mutate(
    longitude = st_coordinates(geometry)[, 1],
    latitude = st_coordinates(geometry)[, 2],
    selected_ = rep(TRUE, nrow(.))
  )

reset_selection <- function(x, brush) {
  if (is.null(brush)) return(rep(TRUE, nrow(x)))
  res <- brushedPoints(x, brush, allRows = TRUE)$selected_
  res
}

histogram <- function(power_plants) {
  power_plants %>%
    ggplot(aes(x = log_capacity, fill = primary_fuel)) +
    geom_histogram(position = "stack", bins = 30) +
    labs(title = "Distribution of log(1+Power) by Fuel",
         x = "log(1+Power)", 
         y = "Count of Plants") +
    scale_y_continuous(expand = c(0, 0))
}

scatterplot <- function(power_plants) {
  power_plants %>%
    ggplot() +
    geom_point(aes(x = longitude, y = latitude, color = primary_fuel, size = capacity_mw), alpha = 0.6) +
    scale_size_continuous(name = "Generation Capacity (MW)") +
    labs(title = "Power Plants in the Upper Midwest",
         x = "Longitude", y = "Latitude", color = "Primary Fuel") +
    theme_minimal()
}

data_table <- function(power_plants) {
  power_plants %>%
    st_drop_geometry() %>%
    select(name, owner, primary_fuel, commissioning_year, capacity_mw) 
}

# Define UI
ui <- fluidPage(
  titlePanel("Interactive Analysis of Power Plants"),
  fluidRow(
    column(6, plotOutput("histogram", brush = brushOpts("plot_brush", direction = "x"))),
    column(6, plotOutput("scatterplot"))
  ),
  dataTableOutput("table")
)

# Define server logic
server <- function(input, output, session) {
  selected <- reactiveVal(rep(TRUE, nrow(power_plants)))
  
  observeEvent(input$plot_brush, {
    sel <- reset_selection(power_plants, input$plot_brush)
    selected(sel)
  })
  
  output$histogram <- renderPlot(histogram(power_plants))
  output$scatterplot <- renderPlot(scatterplot(power_plants %>% filter(selected())))
  output$table <- renderDataTable({data_table(power_plants %>% filter(selected()))})
}

# Run the Shiny app
shinyApp(ui, server)
