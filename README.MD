# Dashboard de Expectativa de Vida

Este proyecto contiene un dashboard interactivo desarrollado en R utilizando la librería `shinydashboard`. El objetivo principal de la aplicación es visualizar cómo varía la expectativa de vida en función del Producto Interno Bruto (GDP) a través de los años, tomando en cuenta la población y el continente de diversos países.

El entorno de desarrollo está completamente estandarizado utilizando **Dev Containers** y el manejo de paquetes de R se realiza mediante **renv**, asegurando la reproducibilidad del proyecto.

## Estructura de Archivos

* **`datos_dashboard_examen.csv`**: Base de datos principal que contiene la información histórica (Año, Continente, País, Expectativa de vida, Población, GDP, etc.) utilizada tanto para la exploración como para el dashboard.
* **`exploracion.Rmd`**: Notebook de R Markdown donde se realizó el análisis exploratorio de los datos (EDA). Aquí se identificaron los tipos de variables, se validaron los rangos fijos para las gráficas y se comprobó la estructura general.
* **`exploracion.html`**: Reporte en formato HTML, ya estilizado, generado a partir de `exploracion.Rmd`. Contiene los resultados, salidas de celdas y visualizaciones estáticas derivadas de la exploración inicial.
* **`app.R`**: Script principal que contiene el código completo de la aplicación Shiny (UI y Server). Al ejecutar este archivo, se levanta el dashboard interactivo.

## Requisitos Previos

Para ejecutar este proyecto en un entorno local aislado y reproducible, necesitarás tener instalado:

1. [Docker](https://www.docker.com/products/docker-desktop/) (Docker Desktop corriendo en tu máquina).
2. [Visual Studio Code (VS Code)](https://code.visualstudio.com/).
3. La extensión **Dev Containers** instalada en VS Code.

## Instrucciones de Setup Local

Sigue estos pasos para levantar el entorno y ejecutar la aplicación:

1. **Clonar el repositorio y abrir en VS Code:**
   Clona este repositorio (especificamente la rama `dashboard/examen1`) en tu máquina local y abre la carpeta del proyecto en Visual Studio Code.

2. **Abrir en el Dev Container:**
   Al abrir el proyecto, VS Code debería detectar la configuración del contenedor y mostrar una notificación en la esquina inferior derecha. Haz clic en **"Reopen in Container"** (Reabrir en contenedor). 
   Docker descargará la imagen y construirá el entorno de R necesario (podria tomar varios minutos la primera vez).

3. **Restaurar las dependencias con renv:**
   Una vez dentro del contenedor, abre la terminal o la consola de R integrada en VS Code y ejecuta el siguiente comando para instalar todas las dependencias exactas del proyecto:
   
    ```R
    renv::restore()
    ```

4. **Ejecutar el Dashboard:**
    Cuando todas las librerías terminen de instalarse, puedes levantar la aplicación Shiny ejecutando:
    ```R
    shiny::runApp("app.R", port="3838", host="0.0.0.0")
    ```
    Esto abrirá el dashboard interactivo en tu navegador o en el visor de VS Code.
