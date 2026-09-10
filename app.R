library(shiny)
library(shinydashboard)
library(tidyverse)

# cargar datos
mantenimiento <- read_csv("mantenimiento.csv", locale = locale(encoding = "latin1"))

ui <- dashboardPage(
    dashboardHeader(title = "Mantenimiento"),
  
    dashboardSidebar(
        sidebarMenu(
        menuItem("Resumen Operativo", tabName = "resumen", icon = icon("cogs"))
        )
    ),

    dashboardBody(
        tabItems(
        tabItem(tabName = "resumen",
                h2("Indicadores de Corto Plazo"),
                p("Aquí colocaremos los KPIs y los gráficos en los siguientes pasos.")
                # Espacio reservado para las cajas (ValueBoxes) y los gráficos (plotOutput)
        )
        )
    )
)

server <- function(input, output, session) {
    # Espacio reservado para calcular los KPIs (renderValueBox)
    # Espacio reservado para generar los gráficos (renderPlot)
}

shinyApp(ui, server)