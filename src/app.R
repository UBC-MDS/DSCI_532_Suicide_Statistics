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
library(gridExtra)

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
        mainPanel(leafletOutput("suicideMap"),
                  plotOutput("suicide_year"),
                  plotOutput("gdp_year"),
                  plotOutput("pop_year"),
                  plotOutput("suicide_age")
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
        location <- geocode(input$location, source="dsk")
        return(location)
    })
    
    output$suicideMap <- renderLeaflet({
        leaflet() %>%
            addProviderTiles(providers$Stamen.TonerLite,
                             options = providerTileOptions(noWrap = TRUE)
            ) %>% 
            setView(getSelectedLocation()$lon, getSelectedLocation()$lat, zoom=3) #TODO set zoom automatically, efficiency could be improved here as well
    })
    
    # a <- suicideData %>% 
    #     group_by(country, year,sex) %>% 
    #     summarise(suicides_total = sum(suicides_no, na.rm = TRUE), pop = sum(population, na.rm = TRUE)) %>% 
    #     left_join(gdpData, by = c("country" = "Country or Area", "year" = "Year")) %>% 
    #     filter(country == "United States of America") %>% 
    #     ggplot(aes(x = year, y = suicides_total)) +
    #     geom_line(aes(color = sex), size = 2) +
    #     theme_bw()
    # b <- suicideData %>% 
    #     group_by(country, year,sex) %>% 
    #     summarise(suicides_total = sum(suicides_no, na.rm = TRUE), pop = sum(population, na.rm = TRUE)) %>% 
    #     left_join(gdpData, by = c("country" = "Country or Area", "year" = "Year")) %>% 
    #     filter(country == "United States of America") %>% 
    #     ggplot(aes(x = year, y = suicides_total)) +
    #     geom_line(aes(color = sex), size = 2) +
    #     theme_bw()
    # c <- suicideData %>% 
    #     group_by(country, year,sex) %>% 
    #     summarise(suicides_total = sum(suicides_no, na.rm = TRUE), pop = sum(population, na.rm = TRUE)) %>% 
    #     left_join(gdpData, by = c("country" = "Country or Area", "year" = "Year")) %>% 
    #     filter(country == "United States of America") %>% 
    #     ggplot(aes(x = year, y = suicides_total)) +
    #     geom_line(aes(color = sex), size = 2) +
    #     theme_bw()
    # d <- suicideData %>% 
    #     group_by(country, year,sex) %>% 
    #     summarise(suicides_total = sum(suicides_no, na.rm = TRUE), pop = sum(population, na.rm = TRUE)) %>% 
    #     left_join(gdpData, by = c("country" = "Country or Area", "year" = "Year")) %>% 
    #     filter(country == "United States of America") %>% 
    #     ggplot(aes(x = year, y = suicides_total)) +
    #     geom_line(aes(color = sex), size = 2) +
    #     theme_bw()
    # 
    # output$suicide_year <- renderPlot(
    #     options(repr.plot.width = 7, repr.plot.height = 2.5)
    #     grid.arrange(a,b,c,d, ncol = 2))
    #     
    # output$gdp_year <- renderPlot(
    #     suicideData %>% 
    #         group_by(country, year,sex) %>% 
    #         summarise(suicides_total = sum(suicides_no, na.rm = TRUE), pop = sum(population, na.rm = TRUE)) %>% 
    #         left_join(gdpData, by = c("country" = "Country or Area", "year" = "Year")) %>% 
    #         filter(country == "United States of America") %>% 
    #         ggplot(aes(x = year, y = suicides_total)) +
    #         geom_line(aes(color = sex), size = 2) +
    #         theme_bw())
    # 
    # output$pop_year <- renderPlot(
    #     suicideData %>% 
    #         group_by(country, year,sex) %>% 
    #         summarise(suicides_total = sum(suicides_no, na.rm = TRUE), pop = sum(population, na.rm = TRUE)) %>% 
    #         left_join(gdpData, by = c("country" = "Country or Area", "year" = "Year")) %>% 
    #         filter(country == "United States of America") %>% 
    #         ggplot(aes(x = year, y = suicides_total)) +
    #         geom_line(aes(color = sex), size = 2) +
    #         theme_bw())
    # 
    # output$suicide_age <- renderPlot(
    #     suicideData %>% 
    #         group_by(country, year,sex) %>% 
    #         summarise(suicides_total = sum(suicides_no, na.rm = TRUE), pop = sum(population, na.rm = TRUE)) %>% 
    #         left_join(gdpData, by = c("country" = "Country or Area", "year" = "Year")) %>% 
    #         filter(country == "United States of America") %>% 
    #         ggplot(aes(x = year, y = suicides_total)) +
    #         geom_line(aes(color = sex), size = 2) +
    #         theme_bw())
    # 
    #         
    # options(repr.plot.width = 7, repr.plot.height = 2.5)
    # grid.arrange(output$suicide_year,output$gdp_year,output$pop_year,output$suicide_age, ncol = 2)
    # 
}

# Run the application 
shinyApp(ui = ui, server = server)
