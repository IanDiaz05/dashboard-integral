library(shiny)
library(shinydashboard)
library(tidyverse)
library(DT)

# cargar datos
mantenimiento <- read_csv("mantenimiento.csv", locale = locale(encoding = "latin1"))

ui <- dashboardPage(
    dashboardHeader(title = "Mantenimiento"),
   
    dashboardSidebar(
        sidebarMenu(
            menuItem("Resumen Operativo", tabName = "resumen", icon = icon("cogs")),
            menuItem("Registro Histórico", tabName = "datos", icon = icon("table"))
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
            ),
            tabItem(tabName = "datos",
                h2("Registro Histórico de Mantenimientos"),
                fluidRow(
                    box(width = 12, title = "Filtros", status = "primary", solidHeader = TRUE, collapsible = TRUE,
                        fluidRow(
                            column(3,
                                dateRangeInput("filtro_fecha", "Rango de Fechas",
                                    start = min(mantenimiento$Fecha),
                                    end = max(mantenimiento$Fecha),
                                    min = min(mantenimiento$Fecha),
                                    max = max(mantenimiento$Fecha),
                                    format = "dd/mm/yyyy",
                                    language = "es"
                                )
                            ),
                            column(3,
                                selectInput("filtro_tipo", "Tipo de Mantenimiento",
                                    choices = unique(mantenimiento$TipoMantenimiento),
                                    selected = unique(mantenimiento$TipoMantenimiento),
                                    multiple = TRUE
                                )
                            ),
                            column(3,
                                selectInput("filtro_tecnico", "Responsable",
                                    choices = unique(mantenimiento$Responsable),
                                    selected = unique(mantenimiento$Responsable),
                                    multiple = TRUE
                                )
                            ),
                            column(3,
                                sliderInput("filtro_duracion", "Duración (min)",
                                    min = min(mantenimiento$Duracion_min),
                                    max = max(mantenimiento$Duracion_min),
                                    value = c(min(mantenimiento$Duracion_min), max(mantenimiento$Duracion_min)),
                                    step = 1
                                )
                            )
                        )
                    )
                ),
                DT::dataTableOutput("tabla_mantenimiento")
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
    
    datos_filtrados <- reactive({
        df <- mantenimiento
        
        if (!is.null(input$filtro_fecha) && length(input$filtro_fecha) == 2) {
            df <- df %>% filter(Fecha >= input$filtro_fecha[1] & Fecha <= input$filtro_fecha[2])
        }
        
        if (!is.null(input$filtro_tipo) && length(input$filtro_tipo) > 0) {
            df <- df %>% filter(TipoMantenimiento %in% input$filtro_tipo)
        }
        
        if (!is.null(input$filtro_tecnico) && length(input$filtro_tecnico) > 0) {
            df <- df %>% filter(Responsable %in% input$filtro_tecnico)
        }
        
        if (!is.null(input$filtro_duracion) && length(input$filtro_duracion) == 2) {
            df <- df %>% filter(Duracion_min >= input$filtro_duracion[1] & Duracion_min <= input$filtro_duracion[2])
        }
        
        df
    })
    
    output$tabla_mantenimiento <- DT::renderDataTable({
        DT::datatable(
            datos_filtrados(),
            extensions = 'Buttons',
            options = list(
                dom = 'Blfrtip',
                buttons = c('copy', 'csv', 'excel', 'pdf', 'print'),
                pageLength = 10,
                lengthMenu = list(c(10, 25, 50, -1), c('10', '25', '50', 'Todos')),
                scrollX = TRUE
            )
        )
    }, server = FALSE)
}

shinyApp(ui, server)