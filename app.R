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
                fluidRow(
                  valueBoxOutput("total_mantenimientos", width = 3),
                  valueBoxOutput("porc_correctivo", width = 3),
                  valueBoxOutput("tiempo_total_paro", width = 3),
                  valueBoxOutput("maquina_top", width = 3)
                ),
                fluidRow(
                  box(width = 6, plotOutput("plot_tendencia")),
                  box(width = 6, plotOutput("plot_paro_maquina"))
                ),
                fluidRow(
                  box(width = 6, plotOutput("plot_causas")),
                  box(width = 6, plotOutput("plot_tecnico"))
                )
        )
        )
    )
)

server <- function(input, output, session) {
    
    output$total_mantenimientos <- renderValueBox({
      total <- nrow(mantenimiento)
      valueBox(
        value = total,
        subtitle = "Total de Mantenimientos",
        icon = icon("cogs"),
        color = "blue"
      )
    })
    
    output$porc_correctivo <- renderValueBox({
      porc <- round(mean(mantenimiento$TipoMantenimiento == "Correctivo") * 100, 1)
      valueBox(
        value = paste0(porc, "%"),
        subtitle = "% de Correctivos",
        icon = icon("exclamation-triangle"),
        color = "red"
      )
    })
    
    output$tiempo_total_paro <- renderValueBox({
      total_paro <- sum(mantenimiento$Duracion_min)
      valueBox(
        value = format(total_paro, big.mark = "."),
        subtitle = "Tiempo Total de Paro (min)",
        icon = icon("clock"),
        color = "orange"
      )
    })
    
    output$maquina_top <- renderValueBox({
      maq <- mantenimiento %>%
        group_by(Máquina) %>%
        summarise(Tiempo_Total = sum(Duracion_min)) %>%
        arrange(desc(Tiempo_Total)) %>%
        slice(1)
      valueBox(
        value = maq$Máquina,
        subtitle = paste("Máquina más problemática:", maq$Tiempo_Total, "min"),
        icon = icon("industry"),
        color = "purple"
      )
    })
    
    output$plot_tendencia <- renderPlot({
      ggplot(mantenimiento, aes(x = Fecha, fill = TipoMantenimiento)) +
        geom_bar() +
        scale_fill_manual(values = c("Preventivo" = "#28a745", "Correctivo" = "#dc3545")) +
        labs(title = "Tendencia Diaria de Mantenimientos", x = "Fecha", y = "Eventos", fill = "Tipo") +
        theme_minimal()
    })
    
    output$plot_paro_maquina <- renderPlot({
      mantenimiento %>%
        group_by(Máquina) %>%
        summarise(Tiempo_Total = sum(Duracion_min)) %>%
        ggplot(aes(x = reorder(Máquina, Tiempo_Total), y = Tiempo_Total)) +
        geom_col(fill = "#007bff") +
        coord_flip() +
        labs(title = "Tiempo de Paro Acumulado", x = "", y = "Minutos Totales") +
        theme_minimal()
    })
    
    output$plot_causas <- renderPlot({
      mantenimiento %>%
        count(Causa) %>%
        ggplot(aes(x = reorder(Causa, n), y = n)) +
        geom_col(fill = "#fd7e14") +
        coord_flip() +
        labs(title = "Principales Causas de Intervención", x = "", y = "Frecuencia") +
        theme_minimal()
    })
    
    output$plot_tecnico <- renderPlot({
      ggplot(mantenimiento, aes(x = fct_infreq(Responsable))) +
        geom_bar(fill = "#6c757d") +
        coord_flip() +
        labs(title = "Intervenciones por Técnico", x = "", y = "Cantidad de Mantenimientos") +
        theme_minimal()
    })
}

shinyApp(ui, server)