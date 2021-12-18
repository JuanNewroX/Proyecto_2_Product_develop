# HEADER ----
header <- dashboardHeader(
  title = "PROYECTO FINAL",
  tags$li(
    class = "dropdown",
    tags$a(HTML(paste("Universidad Galileo")))
  )
)


# SIDEBAR ----
sidebar <- dashboardSidebar(
  h6("JUAN CARLOS ROMERO", style = "color:gray;"),
  sidebarMenu(
    menuItem(text = "Acerca de", tabName = "acerca_de", icon = icon("home"), selected = TRUE),
    menuItem(text = "Mapas", tabName = "mapa_resumen_datos", icon = icon("table")),
    menuItem(text = "Tablas", tabName = "tablas_resumen_datos", icon = icon("table")),
    menuItem(text = "Graficas", tabName = "resumen_graficas", icon = icon("dashboard"))
  ),
  h5("FILTROS-INPUTS", style = "color:gray;"),
  selectInput(inputId = "country", label = "Pais", choices = NULL),
  selectInput(inputId = "estado", label = "Estados", choices = NULL),
  dateRangeInput(
    inputId = "fecha_datos", label = "Rango de fechas",
    start = "2020-01-01", end = Sys.Date(),
    min = "2020-01-01", max = Sys.Date(),
    format = "dd/mm/yyyy", separator = " - "
  ),
  h5("UPDATE FUNCTION", style = "color:gray;"),
  actionButton("reset", "Limpiar filtros")
  
)



body <- dashboardBody(
 
  tabItems(
    tabItem(
      tabName = "acerca_de",
      fluidRow(
        h1(
          id = "titulo",
          "Covid  19  Dashboard",
          align = "center"
        )
      ),
      fluidRow(
        h2("  Instrucciones"),
        p("   Utilizando  los  datos  provistos,  los  cuales  contienen  información  sobre  los  contagios,  las recuperaciones  y  las  muertes,  dados  por  país  y  región.  Se  solicita  que  usted  construya  un  data pipeline  que  procese  los  3  archivos  csv,  los  inserte  a  una  base  de  datos,  y  luego  basado  en  los datos  procesados,  debe  construir  un  dashboard  que  permite  analizar  las  estadísticas  de  cada uno  de  los  archivos.",
          align = "left"
        )
      )
    ),

    tabItem(
      tabName = "mapa_resumen_datos",
      fluidRow(
        column(
          width = 12,
          h4("MAPA", "", align = "left"),
          leafletOutput(outputId = "MapaCasos", height = 600)
        )
      )
    ),
    tabItem(
      tabName = "tablas_resumen_datos",
      fluidRow(
        column(
          width = 12,
          h4("Resumen de datos", "", align = "left"),
          DT::dataTableOutput("tabla_datos")
        )
      )
    ),

    tabItem(
      tabName = "resumen_graficas",
      fluidRow(
        h3("", align = "center"),
        box(
          width = 4,
          plotlyOutput("grafica_muertes")
        ),
        box(
          width = 4,
          plotlyOutput("grafica_confirmados")
        ),
        box(
          width = 4,
          plotlyOutput("grafica_recuperados")
        ),
        
        box(
          width = 12,
          plotlyOutput("grafica_general")
        )
        
        
      )
    )
  )
) 

ui <- dashboardPage(header = header, sidebar = sidebar, body = body)
