#
# This is a Shiny web application. You can run the application by clicking
# the 'Run App' button above.
#
# Find out more about building applications with Shiny here:
#
#    http://shiny.rstudio.com/
#

library(tidyverse)
library(shiny)
library(shinyWidgets)
library(leaflet)
library(leaflet.extras)
library(jsonlite)
library(ggmap)

# Define UI for application that draws a histogram
ui <- fluidPage(

    # Application title
    titlePanel("World Suicide Statistics by Country"),

    # Sidebar with a slider input for number of bins 
    sidebarLayout(
        sidebarPanel(
            uiOutput('location'),
            uiOutput('suicide_total'),
            uiOutput('gdp'),
            uiOutput('population'),
            uiOutput('age'),
            uiOutput("sex")
        ),

        
        # Show a plot of the generated distribution
        mainPanel(
           leafletOutput("suicideMap")
        )
    )
)

# Define server logic required to draw a histogram
server <- function(input, output, session) {
    suicideData = read_csv("../data/who_suicide_statistics.csv")
    gdpData <- read_csv("../data/UN_Gdp_data.csv")
    
    #View(suicideData)
    
    tidy_data <- suicideData %>%
        group_by(country, year) %>%
        summarise(suicides_total = sum(suicides_no, na.rm = TRUE), pop = sum(population, na.rm = TRUE)) %>%
        left_join(gdpData, by = c("country" = "Country or Area", "year" = "Year")) %>%
        select(- "Item")
    
    countries <- suicideData %>% 
        distinct(country) %>% 
        select(country)
    
    ageGroups <- c("5-14", "15-24", "25-34", "35-54", "55-74", "75+")
    
    colMax <- function(data) sapply(data, max, na.rm = TRUE)
    colMin <- function(data) sapply(data, min, na.rm = TRUE)
    
    output$location = renderUI({
        selectInput("location",
                    "Location:",
                    choices = countries
        )
    })
    
    output$suicide_total = renderUI({
        sliderInput("suicide_total", # Get max and min values of gdp
                    "Suicide Total:",
                    min = as.double(colMin(tidy_data)[3]),
                    max = as.double(colMax(tidy_data)[3]),
                    value = c(0, 200000)
        )
    })
    
    output$gdp = renderUI({
        sliderInput("gdp", # Get max and min values of gdp
                    "GDP:",
                    min = round(as.double(colMin(tidy_data)[5]), 3),
                    max = round(as.double(colMax(tidy_data)[5]), 3),
                    value = c(0, 200000)
        )
    })

    output$population = renderUI({
        sliderInput("population", # Get max and min values of population
                    "Population:",
                    min = as.double(colMin(tidy_data)[4]),
                    max = as.double(colMax(tidy_data)[4]),
                    value = c(as.double(colMin(tidy_data)[4]), as.double(colMax(tidy_data)[4]))
        )
    })
    
    output$age = renderUI({
        sliderTextInput("age", # Get categories
                        "Age:",
                        choices = ageGroups, 
                        selected = ageGroups
        )
    })
    
    output$sex = renderUI({
        radioButtons("sex",
                    "Sex:", 
                    choices = c("Male", "Female", "All"),
                    selected = c("All"),
                    inline = TRUE)
    })
    
    getSelectedLocation <- reactive({
        location_to_search <- input$location
        if (is.null(location_to_search)) {
            location_to_search <- "Canada"
        }
        location <- geocode(location_to_search, source="dsk")
        
        return(location)
    })
    
    # https://github.com/datasets/geo-countries/blob/master/data/countries.geojson
    geojson <- readLines("../data/countries.geojson", warn = FALSE) %>%
        paste(collapse = "\n") %>%
        fromJSON(simplifyVector = FALSE)
    
    #View(geojson)
    # Default styles for all features
    geojson$style = list(
        weight = 1,
        color = "#555555",
        opacity = 1,
        fillOpacity = 0.8
    )
    
    # Gather GDP estimate from all countries
    gdp_md_est <- sapply(geojson$features, function(feat) {
        feat$properties$gdp_md_est
    })
    # Gather population estimate from all countries
    pop_est <- sapply(geojson$features, function(feat) {
        max(1, feat$properties$pop_est)
    })
    
    # Color by per-capita GDP using quantiles
    #pal <- colorQuantile("Greens", gdp_md_est / pop_est)
    
    # Add a properties$style list to each feature
    geojson$features <- lapply(geojson$features, function(feat) {
        feat$properties$style <- list(
            #fillColor = pal(
            #    feat$properties$gdp_md_est / max(1, feat$properties$pop_est)
            #)
            fillColor = 1
        )
        feat
    })
    
    
    output$suicideMap <- renderLeaflet({
        leaflet() %>%
            addProviderTiles(providers$CartoDB.PositronNoLabels,
                             options = providerTileOptions(noWrap = TRUE)
            ) %>% 
            addGeoJSON(geojson) %>% # TODO figure out how to make this faster
            setView(getSelectedLocation()$lon, getSelectedLocation()$lat, zoom=3) #TODO set zoom automatically, efficiency could be improved here as well 
            
    })
}

# Run the application 
shinyApp(ui = ui, server = server)
