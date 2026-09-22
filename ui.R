library(shinydashboard)

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
        fluidRow(
            box(
                width = 12,
                title = "Filtro de Año",
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
                )
            )
        ),
        fluidRow(
            box(
                width = 12,
                title = "Gráfico de Burbujas",
                status = "primary",
                solidHeader = TRUE,
                plotlyOutput("bubble_chart")
            )
        )
    )
)
