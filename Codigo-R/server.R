server <- function(input, output, session) {
  datos <- reactive({
    conexion_datos <- dbConnect(
      MySQL(), user = "test",
      password = "test123",
      dbname = "test", host = "127.0.0.1"
    )
    datos  <- dbGetQuery(conexion_datos, "select * from all_data") %>% mutate(
      fecha = dmy(fecha)
    )
    
    dbDisconnect(conexion_datos)
    
    datos
    
  })
  
  fecha_datos1 <- reactive(input$fecha_datos[1])
  fecha_datos2 <- reactive(input$fecha_datos[2])
  
  observeEvent(input$reset, {
    dftmp <- datos()
    updateSelectInput(
      session = session, inputId = "country",
      choices = c("TODOS", unique(dftmp %>% select(Pais) %>% distinct()) , selected  = "TODOS" )
    )
    
    
    updateSelectInput(
      session = session, inputId = "estado",
      choices = c("TODOS", unique(dftmp %>% select(Estado) %>% distinct()) , selected  = "TODOS" )
    )
    
  })
  
  datos_filtrados <- reactive({
    datos_analisis <- datos()
    if(input$country == "TODOS"){
      dftmp <- datos_analisis
    }
    else{
      dftmp <- datos_analisis  %>% filter(Pais == input$country)
    }
    if(input$estado != "TODOS"){
      dftmp <- dftmp %>% filter(Estado == input$estado) 
    }
    
    
    df <- dftmp %>% filter(between(fecha, fecha_datos1(), fecha_datos2()))
    df
  })
 
  
  observeEvent( datos(), {
    updateSelectInput(
      session = session, inputId = "country",
      choices = c("TODOS", unique(datos() %>% select(Pais) %>% distinct()) , selected  = "TODOS" )
    )
  })
  
  observe({
    dftmp <- datos() %>% filter(Pais == input$country)
    
    updateSelectInput(
      session = session, inputId = "estado",
      choices = c("TODOS", unique(dftmp %>% select(Estado) %>% distinct()))
    )
  })
 
  
  observeEvent(input$grafica_id,{
    updateTabsetPanel(session, "params", selected = input$grafica_id)
  })
  
  output$tabla_datos <- DT::renderDataTable({
    datos_filtrados() %>% 
      DT::datatable(filter = 'top', selection = list(
        mode = "single",
        target = "row"
      )) 
  })
  
  output$grafica_muertes <- renderPlotly({
    
    df_plot <- datos_filtrados() %>% mutate(
      anio_mes = ifelse(month(fecha) < 10, paste0(year(fecha) , "-0", month(fecha)), paste0(year(fecha) , "-", month(fecha))))%>% group_by(anio_mes) %>% 
      mutate(n_muertes = sum(death)) %>% select(anio_mes, n_muertes) %>% unique()
    
    plot <-
      plot_ly(
        df_plot,
        x = ~anio_mes, y = ~n_muertes,
        type = "bar", name = "Muertes",
        marker = list(
          color = "#FF0000",
          line = list(color = "#04542C", width = 1.5)
        )
      )
    
    plot
    
  })
  
  
  output$grafica_confirmados <- renderPlotly({
    
    df_plot <- datos_filtrados() %>% mutate(
      anio_mes = ifelse(month(fecha) < 10, paste0(year(fecha) , "-0", month(fecha)), paste0(year(fecha) , "-", month(fecha))))%>% group_by(anio_mes) %>% 
      mutate(n_confirmados = sum(confirmed)) %>% select(anio_mes, n_confirmados) %>% unique()
    
    plot <-
      plot_ly(
        df_plot,
        x = ~anio_mes, y = ~n_confirmados,
        type = "bar", name = "Confirmados",
        marker = list(
          color = "#0000FF",
          line = list(color = "#04542C", width = 1.5)
        )
      )
    
    plot
    
  })
  
  
  output$grafica_recuperados <- renderPlotly({
    
    df_plot <- datos_filtrados() %>% mutate(
      anio_mes = ifelse(month(fecha) < 10, paste0(year(fecha) , "-0", month(fecha)), paste0(year(fecha) , "-", month(fecha))))%>% group_by(anio_mes) %>% 
      mutate(n_recuperados = sum(recovered, na.rm = TRUE)) %>% select(anio_mes, n_recuperados) %>% unique()
    
    plot <-
      plot_ly(
        df_plot,
        x = ~anio_mes, y = ~n_recuperados,
        type = "bar", name = "Recuperados",
        marker = list(
          color = "#00FF00",
          line = list(color = "#04542C", width = 1.5)
        )
      )
    
    plot
    
  })
  
  
  output$grafica_recuperados <- renderPlotly({
    
    df_plot <- datos_filtrados() %>% mutate(
      anio_mes = ifelse(month(fecha) < 10, paste0(year(fecha) , "-0", month(fecha)), paste0(year(fecha) , "-", month(fecha))))%>% group_by(anio_mes) %>% 
      mutate(
        n_recuperados = sum(recovered, na.rm = TRUE)) %>% select(anio_mes, n_recuperados) %>% unique()
    
    plot <-
      plot_ly(
        df_plot,
        x = ~anio_mes, y = ~n_recuperados,
        type = "bar", name = "Recuperados",
        marker = list(
          color = "#00FF00",
          line = list(color = "#04542C", width = 1.5)
        )
      )
    
    plot
    
  }) 
  
  output$grafica_general <- renderPlotly({
    
    df_plot <- datos_filtrados() %>% mutate(
      anio_mes = ifelse(month(fecha) < 10, paste0(year(fecha) , "-0", month(fecha)), paste0(year(fecha) , "-", month(fecha))))%>% group_by(anio_mes) %>% 
      mutate(
        n_recuperados = sum(recovered, na.rm = TRUE),
        n_confirmados = sum(confirmed),
        n_muertes = sum(death)
      ) %>% select(anio_mes, n_confirmados, n_muertes, n_recuperados) %>% unique()
    
    plot <-
      plot_ly(
        df_plot,
        x = ~anio_mes, y = ~n_confirmados,
        name = "Confirmados", type = "scatter",
        mode = "lines+markers",
        line = list(color = "#0000FF"),
        marker = list(color = "#0000FF")
      ) %>%
      add_trace(
        y = ~n_muertes, name = "Muertes",
        mode = "lines+markers",
        line = list(color = "#FF0000"),
        marker = list(color = "#FF0000")
      ) %>%
      add_trace(
        y = ~n_recuperados, name = "Recuperados",
        mode = "lines+markers",
        line = list(color = "#00FF00"),
        marker = list(color = "#00FF00")
      )%>%
      layout(
        xaxis = list(title = "Mes"),
        yaxis = list(title = "No. Personas"),
        legend = list(orientation = "h", x = -0, y = -0.5)
      )
    
    plot
    
  })
  
  output$MapaCasos <- renderLeaflet({
    
    
    datos_filtrados()  %>% group_by(Pais) %>% mutate(
      confirmed = sum(confirmed),
      death = sum(death),
      recovered = sum(recovered)
      
    ) %>%  select(Pais, confirmed, death, recovered, Long, Lat) %>% unique() %>% leaflet() %>%
      addProviderTiles("CartoDB.Positron", group = "Mapa administrativo") %>%
      addProviderTiles("Esri.WorldImagery", group = "Mapa satelital") %>%
      setView(lng = -91.51806, lat = 14.83472, zoom = 2) %>% 
      addTiles() %>%
      addCircles(lng = ~Long, lat = ~Lat, weight = 1,
                 radius = ~sqrt(confirmed) * 10, popup = ~ paste0(Pais, ":", confirmed) , color = "#0000FF", group = "Confirmados"
      ) %>% 
      addCircles(lng = ~Long, lat = ~Lat, weight = 1,
                 radius = ~sqrt(death) * 10, popup = ~ paste0(Pais, ":", death) , color = "#FF0000", group = "Muertes"
      ) %>% 
      addCircles(lng = ~Long, lat = ~Lat, weight = 1,
                 radius = ~sqrt(recovered) * 10, popup = ~ paste0(Pais, ":", recovered) , color = "#00FF00", group = "Recuperados"
      ) %>% addLayersControl(
        overlayGroups = c("Mapa administrativo", "Mapa satelital", 
                          "Confirmados", 
                          "Muertes",
                          "Recuperados"),
        options = layersControlOptions(collapsed = FALSE)
      ) %>%  addLegend(
        position = "bottomright",
        colors = c("#0000FF", "#FF0000", "#00FF00"), 
        labels = c("Confirmados", "Muertes", "Recuperados"),
        opacity = 1
      )
    
    
  })
}

