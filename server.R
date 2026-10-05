library(shiny)
library(shinydashboard)
library(shinyWidgets)
library(DT)
library(plotly)
library(dplyr)
library(scales)
library(lubridate)

# 1. Carga y preparación inicial (segura)
ventas <- tryCatch(
  {
    df <- read.csv("ventas_clean.csv", stringsAsFactors = FALSE, fileEncoding = "UTF-8")
    df$fecha <- as.Date(df$fecha)
    # `mes` ("YYYY-MM") ordenado cronologicamente como factor
    df$mes <- factor(df$mes, levels = sort(unique(df$mes)))
    df$region <- factor(df$region, levels = c("Norte", "Sur", "Este", "Oeste"))
    df$producto <- factor(df$producto, levels = sort(unique(as.character(df$producto))))
    df
  },
  error = function(e) {
    warning("No se pudo leer ventas_clean.csv: ", conditionMessage(e))
    data.frame(
      fecha = as.Date(character()),
      mes = factor(),
      region = factor(),
      producto = factor(),
      unidades_vendidas = numeric(),
      precio_unitario = numeric(),
      ingreso_total = numeric(),
      ticket_promedio = numeric()
    )
  }
)

min_fecha_global <- if (nrow(ventas) > 0) min(ventas$fecha, na.rm = TRUE) else Sys.Date() - 180
max_fecha_global <- if (nrow(ventas) > 0) max(ventas$fecha, na.rm = TRUE) else Sys.Date()
regiones_global <- if (nrow(ventas) > 0) sort(unique(as.character(ventas$region))) else c("Norte", "Sur", "Este", "Oeste")
productos_global <- if (nrow(ventas) > 0) sort(unique(as.character(ventas$producto))) else c("Producto A", "Producto B", "Producto C")

server <- function(input, output, session) {

  # Restablecer filtros a los valores globales
  observeEvent(input$reset_filtros, {
    updateDateRangeInput(session, "filtro_fecha",
                         start = min_fecha_global, end = max_fecha_global,
                         min = min_fecha_global, max = max_fecha_global)
    updatePickerInput(session, "filtro_region", selected = regiones_global)
    updatePickerInput(session, "filtro_producto", selected = productos_global)
  })

  # 2. Datos reactivos: unico punto de filtrado
  data_filtrada <- reactive({
    req(input$filtro_fecha, input$filtro_region, input$filtro_producto)
    datos <- ventas %>%
      filter(
        fecha >= as.Date(input$filtro_fecha[1]),
        fecha <= as.Date(input$filtro_fecha[2]),
        as.character(region) %in% input$filtro_region,
        as.character(producto) %in% input$filtro_producto
      )
    validate(need(nrow(datos) > 0, "No hay datos para la selección actual. Ajuste los filtros."))
    datos
  })

  # ---- ValueBoxes ejecutivos ----
  output$vb_ingreso <- renderValueBox({
    d <- data_filtrada()
    valueBox(
      value = paste0("$", comma(sum(d$ingreso_total, na.rm = TRUE))),
      subtitle = "Ingreso Total",
      icon = icon("dollar-sign"),
      color = "navy"
    )
  })

  output$vb_unidades <- renderValueBox({
    d <- data_filtrada()
    valueBox(
      value = comma(sum(d$unidades_vendidas, na.rm = TRUE)),
      subtitle = "Unidades Totales",
      icon = icon("cubes"),
      color = "purple"
    )
  })

  output$vb_ticket <- renderValueBox({
    d <- data_filtrada()
    ticket <- sum(d$ingreso_total, na.rm = TRUE) / sum(d$unidades_vendidas, na.rm = TRUE)
    valueBox(
      value = dollar(ticket, prefix = "$", accuracy = 0.01),
      subtitle = "Ticket Promedio (precio efectivo)",
      icon = icon("receipt"),
      color = "teal"
    )
  })

  output$vb_lider <- renderValueBox({
    d <- data_filtrada()
    top_region <- d %>%
      group_by(region) %>%
      summarise(t = sum(ingreso_total, na.rm = TRUE), .groups = "drop") %>%
      arrange(desc(t)) %>%
      slice(1)
    top_prod <- d %>%
      group_by(producto) %>%
      summarise(t = sum(ingreso_total, na.rm = TRUE), .groups = "drop") %>%
      arrange(desc(t)) %>%
      slice(1)
    valueBox(
      value = as.character(top_region$region[1]),
      subtitle = paste0("Región Líder | Prod: ", as.character(top_prod$producto[1])),
      icon = icon("trophy"),
      color = "green"
    )
  })

  # ---- Plot 1: Ingreso mensual (linea + marcadores) ----
  output$plot_ingreso_mensual <- renderPlotly({
    d <- data_filtrada()
    ingreso_mensual <- d %>%
      group_by(mes) %>%
      summarise(ingreso = sum(ingreso_total, na.rm = TRUE),
                unidades = sum(unidades_vendidas, na.rm = TRUE),
                .groups = "drop") %>%
      arrange(mes)
    plot_ly(ingreso_mensual, x = ~mes, y = ~ingreso,
            type = "scatter", mode = "lines+markers",
            line = list(width = 3),
            hovertemplate = "%{x}<br>$%{y:,.0f}<extra></extra>") %>%
      layout(title = "Ingreso mensual",
             xaxis = list(title = ""),
             yaxis = list(title = "Ingreso ($)"))
  })

  # ---- Plot 2: Ranking regional (barras horizontales + cuota) ----
  output$plot_ingreso_region <- renderPlotly({
    d <- data_filtrada()
    ingreso_region <- d %>%
      group_by(region) %>%
      summarise(ingreso = sum(ingreso_total, na.rm = TRUE),
                unidades = sum(unidades_vendidas, na.rm = TRUE),
                .groups = "drop") %>%
      mutate(participacion = ingreso / sum(ingreso) * 100) %>%
      arrange(desc(ingreso))
    plot_ly(ingreso_region, x = ~ingreso, y = ~reorder(region, ingreso),
            type = "bar", orientation = "h",
            text = ~paste0("$", comma(ingreso), "  (", round(participacion, 1), "%)"),
            textposition = "outside") %>%
      layout(title = "Ingreso por región",
             xaxis = list(title = "Ingreso ($)"),
             yaxis = list(title = ""))
  })

  # ---- Plot 3: Evolucion temporal comparativa por region ----
  output$plot_evolucion_region <- renderPlotly({
    d <- data_filtrada()
    region_mes <- d %>%
      group_by(mes, region) %>%
      summarise(ingreso = sum(ingreso_total, na.rm = TRUE), .groups = "drop") %>%
      arrange(mes)
    plot_ly(region_mes, x = ~mes, y = ~ingreso, color = ~region,
            type = "scatter", mode = "lines+markers",
            hovertemplate = "%{fullData.name}<br>%{x}: $%{y:,.0f}<extra></extra>") %>%
      layout(title = "Evolución mensual por región",
             xaxis = list(title = ""),
             yaxis = list(title = "Ingreso ($)"))
  })

  # ---- Plot 4: Ingreso por producto ----
  output$plot_ingreso_producto <- renderPlotly({
    d <- data_filtrada()
    ingreso_producto <- d %>%
      group_by(producto) %>%
      summarise(ingreso = sum(ingreso_total, na.rm = TRUE),
                unidades = sum(unidades_vendidas, na.rm = TRUE),
                .groups = "drop") %>%
      mutate(participacion = ingreso / sum(ingreso) * 100) %>%
      arrange(desc(ingreso))
    plot_ly(ingreso_producto, x = ~ingreso, y = ~reorder(producto, ingreso),
            type = "bar", orientation = "h",
            text = ~paste0("$", comma(ingreso), "  (", round(participacion, 1), "%)"),
            textposition = "outside") %>%
      layout(title = "Ingreso por producto",
             xaxis = list(title = "Ingreso ($)"),
             yaxis = list(title = ""))
  })

  # ---- Plot 5: Mix de producto por region (100% apilado, base ingreso) ----
  output$plot_mix_region <- renderPlotly({
    d <- data_filtrada()
    mix_rp <- d %>%
      group_by(region, producto) %>%
      summarise(ingreso = sum(ingreso_total, na.rm = TRUE), .groups = "drop") %>%
      group_by(region) %>%
      mutate(porcentaje = ingreso / sum(ingreso) * 100) %>%
      ungroup()
    plot_ly(mix_rp, x = ~region, y = ~porcentaje, color = ~producto,
            type = "bar",
            hovertemplate = "%{fullData.name} en %{x}: %{y:.1f}%<extra></extra>") %>%
      layout(title = "Mix de productos por región (%)",
             barmode = "stack",
             xaxis = list(title = ""),
             yaxis = list(title = "% del ingreso regional", ticksuffix = "%"))
  })

  # ---- Plot 6: Precio promedio ponderado por region ----
  output$plot_precio_ponderado <- renderPlotly({
    d <- data_filtrada()
    precio_region <- d %>%
      group_by(region) %>%
      summarise(precio_prom = sum(ingreso_total, na.rm = TRUE) / sum(unidades_vendidas, na.rm = TRUE),
                .groups = "drop")
    plot_ly(precio_region, x = ~region, y = ~precio_prom,
            type = "bar", text = ~paste0("$", round(precio_prom, 2)),
            textposition = "outside",
            hovertemplate = "%{x}: $%{y:.2f}<extra></extra>") %>%
      layout(title = "Precio promedio ponderado por región",
             xaxis = list(title = ""),
             yaxis = list(title = "Precio ($)"))
  })

  # ---- Plot 7: Distribucion de unidades vendidas ----
  output$plot_distribucion_unidades <- renderPlotly({
    d <- data_filtrada()
    plot_ly(d, x = ~unidades_vendidas, type = "histogram", nbinsx = 20) %>%
      layout(title = "Distribución de unidades vendidas",
             xaxis = list(title = "Unidades"),
             yaxis = list(title = "Frecuencia"))
  })

  # ---- Tabla maestra con exportacion ----
  output$tabla_ventas <- renderDT({
    d <- data_filtrada()
    cols <- intersect(
      c("fecha", "mes", "region", "producto", "unidades_vendidas",
        "precio_unitario", "ingreso_total", "ticket_promedio"),
      names(d)
    )
    dt <- datatable(
      d %>% select(all_of(cols)),
      extensions = c("Buttons"),
      options = list(
        pageLength = 10,
        lengthMenu = c(10, 25, 50, 100),
        scrollX = TRUE,
        dom = "Blfrtip",
        buttons = c("copy", "csv", "excel", "pdf", "print")
      ),
      filter = "top",
      rownames = FALSE,
      caption = "Detalle de ventas"
    )
    if ("ingreso_total" %in% cols) {
      dt <- formatCurrency(dt, "ingreso_total", currency = "$", digits = 0, mark = ",")
    }
    if ("precio_unitario" %in% cols) {
      dt <- formatCurrency(dt, "precio_unitario", currency = "$", digits = 2, mark = ",")
    }
    if ("ticket_promedio" %in% cols) {
      dt <- formatCurrency(dt, "ticket_promedio", currency = "$", digits = 2, mark = ",")
    }
    if ("unidades_vendidas" %in% cols) {
      dt <- formatRound(dt, "unidades_vendidas", digits = 0, mark = ",")
    }
    dt
  })
}
