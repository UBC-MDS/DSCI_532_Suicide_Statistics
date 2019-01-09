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
library(ggmap)

# Define UI for application that draws a histogram
ui <- fluidPage(

    # Application title
    titlePanel("World Suicide Statistics by Country"),

    # Sidebar with a slider input for number of bins 
    sidebarLayout(
        sidebarPanel(
            uiOutput('location'),
            uiOutput('gdp'),
            uiOutput('population'),
            uiOutput('age')
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

    countries <- suicideData %>% 
        select(country) %>% 
        distinct(country)
    
    ageGroups <- suicideData %>% 
        select(age) %>% 
        distinct(age) %>% 
        # TODO sort logically
        as.list()
    
    populationMax <- suicideData
    
    getSelectedLocation <- reactive({
        location <- geocode(input$location, source="dsk")
        print(location)
        return(location)
    })
    
    output$location = renderUI({
        selectInput("location",
                    "Location:",
                    choices=countries
        )
    })
    
    output$gdp = renderUI({
        sliderInput("gdp", # Get max and min values of gdp
                    "GDP:",
                    min = 0,
                    max = 200000,
                    value = 30
        )
    })
    
    output$population = renderUI({
        sliderInput("population", # Get max and min values of population
                    "Population:",
                    min = 0,
                    max = 200000,
                    value = 30
        )
    })
    
    output$age = renderUI({
        sliderTextInput("age", # Get categories
                        "Age:",
                        choices = ageGroups$age, 
                        selected = ageGroups$age
        )
    })
    
    output$suicideMap <- renderLeaflet({
        leaflet() %>%
            addProviderTiles(providers$Stamen.TonerLite,
                             options = providerTileOptions(noWrap = TRUE)
            ) %>% 
            setView(getSelectedLocation()$lon, getSelectedLocation()$lat, zoom=3) #TODO set zoom automatically, efficiency could be improved here as well
    })
}

# Run the application 
shinyApp(ui = ui, server = server)
