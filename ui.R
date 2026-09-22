library(shinydashboard)
library(DT)

ui <- dashboardPage(

    dashboardHeader(
        title = "Dashboard - Expectativa de Vida"
    ),

    dashboardSidebar(
        sidebarMenu(
            menuItem("Explorador", tabName = "explorador")
        )
    ),

    dashboardBody(
        tabItems(
            tabItem(
                tabName = "explorador",

                # Fila 1: KPIs
                fluidRow(
                    valueBoxOutput("vbox_avg_life", width = 4),
                    valueBoxOutput("vbox_total_pop", width = 4),
                    valueBoxOutput("vbox_top_country", width = 4)
                ),

                # Fila 2: filtro de año + gráfico principal de burbujas
                fluidRow(
                    box(
                        width = 12,
                        title = "Expectativa de Vida vs. PIB per cápita",
                        status = "primary",
                        solidHeader = TRUE,
                        sliderInput(
                            inputId = "year_slider",
                            label = "Selecciona el Año:",
                            min = 2000,
                            max = 2015,
                            value = 2015,
                            step = 1,
                            sep = ""
                        ),
                        plotlyOutput("bubble_chart", height = "550px")
                    )
                ),

                # Fila 3: tendencia histórica + boxplot por Status
                fluidRow(
                    box(
                        width = 6,
                        title = "Evolución Histórica por Continente",
                        status = "primary",
                        solidHeader = TRUE,
                        plotlyOutput("line_trend_chart", height = "400px")
                    ),
                    box(
                        width = 6,
                        title = "Expectativa de Vida por Status",
                        status = "primary",
                        solidHeader = TRUE,
                        plotlyOutput("boxplot_status_chart", height = "400px")
                    )
                ),

                # Fila 4: top 10 países por PIB + tabla interactiva
                fluidRow(
                    box(
                        width = 6,
                        title = "Top 10 Países por PIB",
                        status = "primary",
                        solidHeader = TRUE,
                        plotlyOutput("bar_top10_chart", height = "420px")
                    ),
                    box(
                        width = 6,
                        title = "Detalle de los Datos",
                        status = "primary",
                        solidHeader = TRUE,
                        DTOutput("data_table")
                    )
                )
            )
        )
    )
)
