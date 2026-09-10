# Dashboard de Mantenimiento - ShinyApp

## Configuración del Entorno (Setup)

Este proyecto está configurado para ejecutarse dentro de un contenedor de desarrollo (DevContainer) para garantizar que todas las dependencias y versiones sean consistentes. 

Sigue estos pasos para preparar tu entorno:

1. Asegúrate de tener **Docker** instalado y ejecutándose en tu sistema.
2. Clona este repositorio y ábrelo en **Visual Studio Code**.
3. Al abrir el proyecto, VS Code mostrará una notificación en la parte inferior derecha. Haz clic en **"Reopen in Container"** (Reabrir en contenedor).
4. Espera a que se construya el contenedor y se instale todo el entorno (este proceso podría tardar varios minutos la primera vez).
5. **Importante:** Cualquier comando de R debe ejecutarse exclusivamente a través de la **terminal integrada** de Visual Studio Code. La terminal normal de tu sistema no funcionará, ya que todo el entorno de trabajo está aislado dentro del devcontainer.
6. Una vez que el contenedor esté listo, abre una terminal integrada en VS Code, escribe `R` y presiona Enter para iniciar la consola interactiva.
7. Ejecuta el comando `renv::restore()` para descargar e instalar todas las dependencias de R necesarias para el proyecto.

## Archivos Incluidos

* `mantenimiento.csv`: Dataset principal incluido en el repositorio que alimenta los datos del proyecto.
* `exploracion.Rmd`: Notebook de R que contiene el código utilizado para la exploración inicial y diagnóstico de los datos.
* `exploracion.nb.html`: Reporte visual en formato HTML generado a partir de la ejecución del notebook de exploración.

---

## Estructura del Dashboard

El objetivo de esta ShinyApp es proporcionar un dashboard integral (estratégico, táctico y operativo) dirigido a los supervisores del día a día, centrado en indicadores de corto plazo. 

A partir de la exploración de datos, el dashboard se compone de los siguientes elementos:

### 1. Indicadores Clave (KPIs)
Tarjetas de resumen rápido ubicadas en la parte superior para un vistazo inmediato al estado operativo:
* **Total de Mantenimientos:** Conteo total de registros en el periodo.
* **% de Mantenimiento Correctivo:** Proporción de mantenimientos correctivos frente al total (indicador crítico de problemas operativos vs. prevención).
* **Tiempo Total de Paro:** Suma de la duración en minutos, reflejando el tiempo invertido o de producción perdida.
* **Máquina más problemática:** Identificación de la línea de producción con más registros o más tiempo de paro acumulado.

### 2. Gráficos Principales
* **Gráfico de Tendencia (Líneas / Barras apiladas):** Evolución diaria (Fecha vs. Conteo de eventos o Duración), separada por Tipo de Mantenimiento (Preventivo vs. Correctivo). Permite identificar picos de fallas en días específicos.
* **Análisis por Máquina (Barras horizontales):** Cruce de la Máquina contra el tiempo de paro acumulado. Ayuda a identificar rápidamente qué equipo consume más recursos técnicos.
* **Distribución de Causas (Barras o Dona):** Categoriza las causas de los mantenimientos. Facilita entender la raíz principal de los problemas en piso.
* **Carga de Trabajo por Técnico (Barras):** Muestra el número de intervenciones realizadas por cada responsable, ideal para monitorear el balance de las tareas en el equipo.