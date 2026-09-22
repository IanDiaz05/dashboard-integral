library(DT)

# 1. Carga inicial de datos (fuera de la función server)
df <- read.csv("datos_dashboard_examen.csv", stringsAsFactors = FALSE)

# Formato de números grandes: comas como separador de miles y punto decimal
fmt_miles <- function(x) {
    format(x, big.mark = ",", decimal.mark = ".", scientific = FALSE, trim = TRUE)
}

server <- function(input, output, session) {

    # 2. Dataset reactivo filtrado por el año seleccionado --------------------
    df_filtered <- reactive({
        req(input$year_slider)
        df %>% filter(Year == input$year_slider)
    })

    # 3. ValueBoxes ----------------------------------------------------------

    # Promedio de expectativa de vida del año seleccionado
    output$vbox_avg_life <- renderValueBox({
        datos <- df_filtered()
        req(nrow(datos) > 0)

        promedio <- mean(datos$Lifeexpectancy, na.rm = TRUE)

        valueBox(
            value = format(round(promedio, 2), big.mark = ",", decimal.mark = ".",
                           scientific = FALSE, trim = TRUE, nsmall = 2),
            subtitle = "Expectativa de Vida Promedio",
            icon = icon("heart"),
            color = "aqua"
        )
    })

    # Población total del año seleccionado
    output$vbox_total_pop <- renderValueBox({
        datos <- df_filtered()
        req(nrow(datos) > 0)

        total_poblacion <- sum(as.numeric(datos$Population), na.rm = TRUE)

        valueBox(
            value = format(total_poblacion, big.mark = ",", decimal.mark = ".",
                           scientific = FALSE, trim = TRUE),
            subtitle = "Población Total",
            icon = icon("users"),
            color = "green"
        )
    })

    # País con mayor expectativa de vida
    output$vbox_top_country <- renderValueBox({
        datos <- df_filtered()
        req(nrow(datos) > 0)

        pais_top <- datos$Country[which.max(datos$Lifeexpectancy)]

        valueBox(
            value = pais_top,
            subtitle = "País con Mayor Expectativa de Vida",
            icon = icon("trophy"),
            color = "yellow"
        )
    })

    # 4. Gráficos Plotly -----------------------------------------------------

    # Gráfico de burbujas: Expectativa de Vida vs GDP
    output$bubble_chart <- renderPlotly({
        p_burbujas <- ggplot(
            df_filtered(),
            aes(x = GDP, y = Lifeexpectancy, size = Population, color = Continent)
        ) +
            geom_point(alpha = 0.7) +
            scale_x_continuous(limits = c(1.68, 119172.74), labels = fmt_miles) +
            scale_y_continuous(limits = c(36.3, 89.0)) +
            scale_color_brewer(palette = "Set2") +
            guides(size = "none") +
            labs(
                x = "PIB per cápita",
                y = "Expectativa de Vida",
                color = "Continente"
            )

        ggplotly(p_burbujas)
    })

    # Evolución histórica (usa el dataset completo, no el reactivo)
    output$line_trend_chart <- renderPlotly({
        df_linea <- df %>%
            group_by(Year, Continent) %>%
            summarise(
                LifeExp = mean(Lifeexpectancy, na.rm = TRUE),
                .groups = "drop"
            )

        p_linea <- ggplot(
            df_linea,
            aes(x = Year, y = LifeExp, color = Continent, group = Continent)
        ) +
            geom_line(linewidth = 1) +
            geom_point(size = 2) +
            scale_color_brewer(palette = "Set2") +
            labs(
                x = "Año",
                y = "Expectativa de Vida Promedio",
                color = "Continente"
            )

        ggplotly(p_linea)
    })

    # Boxplot: Expectativa de Vida según Status (dataset reactivo)
    output$boxplot_status_chart <- renderPlotly({
        p_boxplot <- ggplot(
            df_filtered(),
            aes(x = Status, y = Lifeexpectancy, fill = Status)
        ) +
            geom_boxplot(alpha = 0.85, outlier.color = "gray50", outlier.size = 1.5) +
            scale_fill_brewer(palette = "Set2") +
            labs(x = "Status", y = "Expectativa de Vida", fill = "Status")

        ggplotly(p_boxplot)
    })

    # Top 10 países con mayor GDP del año seleccionado
    output$bar_top10_chart <- renderPlotly({
        top10 <- df_filtered() %>%
            arrange(desc(GDP)) %>%
            head(10)

        p_top10 <- ggplot(
            top10,
            aes(x = reorder(Country, GDP), y = GDP, fill = Continent)
        ) +
            geom_col() +
            coord_flip() +
            scale_fill_brewer(palette = "Set2") +
            scale_y_continuous(labels = fmt_miles) +
            labs(x = "País", y = "PIB per cápita", fill = "Continente")

        ggplotly(p_top10)
    })

    # 5. Tabla interactiva ---------------------------------------------------

    output$data_table <- renderDT({
        datatable(
            df_filtered(),
            options = list(pageLength = 5, scrollX = TRUE),
            rownames = FALSE
        ) %>%
            formatRound("Population", digits = 0, mark = ",", dec.mark = ".") %>%
            formatRound("GDP", digits = 2, mark = ",", dec.mark = ".")
    })
}
