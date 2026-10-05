library(shiny)
library(shinydashboard)
library(shinyWidgets)
library(DT)
library(plotly)

# Lectura ligera solo para inicializar los filtros globales.
# Si el CSV no existe, se usan valores por defecto seguros.
ventas_init <- tryCatch(
  {
    df0 <- read.csv("ventas_clean.csv", stringsAsFactors = FALSE, fileEncoding = "UTF-8")
    df0$fecha <- as.Date(df0$fecha)
    df0
  },
  error = function(e) NULL
)

if (!is.null(ventas_init) && nrow(ventas_init) > 0) {
  min_fecha <- min(ventas_init$fecha, na.rm = TRUE)
  max_fecha <- max(ventas_init$fecha, na.rm = TRUE)
  regiones <- sort(unique(ventas_init$region))
  productos <- sort(unique(ventas_init$producto))
} else {
  min_fecha <- Sys.Date() - 180
  max_fecha <- Sys.Date()
  regiones <- c("Norte", "Sur", "Este", "Oeste")
  productos <- c("Producto A", "Producto B", "Producto C")
}

ui <- dashboardPage(
  dashboardHeader(title = "Executive Sales Intelligence", titleWidth = 320),

  dashboardSidebar(
    width = 320,
    sidebarMenu(
      id = "tabs",
      menuItem("Visión Estratégica", tabName = "vision", icon = icon("chart-line")),
      menuItem("Análisis Comercial & Mix", tabName = "mix", icon = icon("boxes")),
      menuItem("Explorador de Datos", tabName = "explorador", icon = icon("table"))
    ),
    hr(),
    h4("Filtros Globales", style = "margin-left:15px; color:#ecf0f1; font-weight:bold;"),
    div(
      style = "margin: 0 15px 15px 15px;",
      dateRangeInput(
        inputId = "filtro_fecha",
        label = "Rango Histórico:",
        start = min_fecha,
        end = max_fecha,
        min = min_fecha,
        max = max_fecha,
        format = "yyyy-mm-dd",
        separator = " a ",
        language = "es"
      ),
      pickerInput(
        inputId = "filtro_region",
        label = "Región:",
        choices = regiones,
        selected = regiones,
        multiple = TRUE,
        options = list(`actions-box` = TRUE, `live-search` = TRUE)
      ),
      pickerInput(
        inputId = "filtro_producto",
        label = "Producto:",
        choices = productos,
        selected = productos,
        multiple = TRUE,
        options = list(`actions-box` = TRUE, `live-search` = TRUE)
      ),
      actionButton(
        inputId = "reset_filtros",
        label = "Restablecer Filtros",
        icon = icon("sync"),
        width = "100%"
      )
    )
  ),

  dashboardBody(
    tags$head(
      tags$style(HTML(".content-wrapper, .right-side { background-color: #f4f6f9; }"))
    ),
    tabItems(
      # ---- Pestaña 1: Visión Estratégica ----
      tabItem(
        tabName = "vision",
        fluidRow(
          valueBoxOutput("vb_ingreso", width = 3),
          valueBoxOutput("vb_unidades", width = 3),
          valueBoxOutput("vb_ticket", width = 3),
          valueBoxOutput("vb_lider", width = 3)
        ),
        fluidRow(
          box(
            width = 8, status = "primary", solidHeader = TRUE,
            title = "Tendencia de Ingresos Mensuales",
            plotlyOutput("plot_ingreso_mensual", height = "350px")
          ),
          box(
            width = 4, status = "primary", solidHeader = TRUE,
            title = "Distribución y Cuota por Región",
            plotlyOutput("plot_ingreso_region", height = "350px")
          )
        ),
        fluidRow(
          box(
            width = 12, status = "primary", solidHeader = TRUE,
            title = "Evolución Temporal Comparativa por Región",
            plotlyOutput("plot_evolucion_region", height = "350px")
          )
        )
      ),

      # ---- Pestaña 2: Análisis Comercial & Mix ----
      tabItem(
        tabName = "mix",
        fluidRow(
          box(
            width = 6, status = "warning", solidHeader = TRUE,
            title = "Ingreso y Participación por Producto",
            plotlyOutput("plot_ingreso_producto", height = "380px")
          ),
          box(
            width = 6, status = "warning", solidHeader = TRUE,
            title = "Mix de Productos por Región (% 100% Apilado)",
            plotlyOutput("plot_mix_region", height = "380px")
          )
        ),
        fluidRow(
          box(
            width = 6, status = "warning", solidHeader = TRUE,
            title = "Precio Promedio Ponderado Efectivo por Región",
            plotlyOutput("plot_precio_ponderado", height = "380px")
          ),
          box(
            width = 6, status = "warning", solidHeader = TRUE,
            title = "Distribución de Volumen por Transacción",
            plotlyOutput("plot_distribucion_unidades", height = "380px")
          )
        )
      ),

      # ---- Pestaña 3: Explorador de Datos ----
      tabItem(
        tabName = "explorador",
        fluidRow(
          box(
            width = 12, status = "info", solidHeader = TRUE,
            title = "Detalle Transaccional Filtrado",
            DTOutput("tabla_ventas")
          )
        )
      )
    )
  )
)
