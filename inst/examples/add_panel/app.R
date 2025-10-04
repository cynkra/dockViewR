library(dockViewR)
library(shiny)
library(bslib)
library(visNetwork)

nodes <- data.frame(id = 1:3)
edges <- data.frame(from = c(1, 2), to = c(1, 3))

ui <- page_fillable(
  actionButton("btn", "add Panel"),
  dockViewOutput("dock")
)

server <- function(input, output, session) {
  exportTestValues(
    panel_ids = get_panels_ids("dock"),
    active_group = get_active_group("dock"),
    grid = get_grid("dock")
  )

  output$dock <- renderDockView({
    dock_view(
      add_tab = list(enable = TRUE),
      panels = list(
        panel(
          id = "1",
          title = "Panel 1",
          content = tagList(
            sliderInput(
              "obs",
              "Number of observations:",
              min = 0,
              max = 1000,
              value = 500
            ),
            plotOutput("distPlot")
          )
        ),
        panel(
          id = "2",
          title = "Panel 2",
          content = tagList(
            visNetworkOutput("network")
          ),
          position = list(
            referencePanel = "1",
            direction = "right"
          ),
          minimumWidth = 500
        ),
        panel(
          id = "3",
          title = "Panel 3",
          content = tagList(
            selectInput(
              "variable",
              "Variable:",
              c("Cylinders" = "cyl", "Transmission" = "am", "Gears" = "gear")
            ),
            tableOutput("data")
          ),
          position = list(
            referencePanel = "2",
            direction = "below"
          )
        )
      ),
      theme = "replit"
    )
  })

  output$distPlot <- renderPlot({
    req(input$obs)
    hist(rnorm(input$obs))
  })

  output$network <- renderVisNetwork({
    visNetwork(nodes, edges, width = "100%")
  })

  output$data <- renderTable(
    {
      mtcars[, c("mpg", input$variable), drop = FALSE]
    },
    rownames = TRUE
  )

  output$plot <- renderPlot({
    dist <- switch(
      input$dist,
      norm = rnorm,
      unif = runif,
      lnorm = rlnorm,
      exp = rexp,
      rnorm
    )

    hist(dist(500))
  })

  observeEvent(input$btn, {
    pnl <- panel(
      id = "new_1",
      title = "Dynamic panel",
      content = tagList(
        radioButtons(
          "dist",
          "Distribution type:",
          c(
            "Normal" = "norm",
            "Uniform" = "unif",
            "Log-normal" = "lnorm",
            "Exponential" = "exp"
          )
        ),
        plotOutput("plot")
      ),
      position = list(
        referencePanel = "1",
        direction = "within"
      ),
      remove = list(enable = TRUE, mode = "manual")
    )
    add_panel(
      "dock",
      pnl
    )
  })

  observeEvent(input[["dock_added-panel"]], {
    showNotification(
      paste("Panel added:", input[["dock_added-panel"]]),
      type = "message"
    )
  })

  # Manually remove a panel after clicking on the button
  observeEvent(input[["dock_panel-to-remove"]], {
    showNotification(
      paste("Removing panel:", input[["dock_panel-to-remove"]]),
      type = "message"
    )
    remove_panel(
      "dock",
      input[["dock_panel-to-remove"]]
    )
  })

  # Manually add a panel after clicking on the + button
  observeEvent(input[["dock_panel-to-add"]], {
    add_panel(
      "dock",
      panel(
        id = as.character(as.numeric(tail(get_panels_ids("dock"), 1)) + 1),
        title = paste(
          "Panel",
          as.character(as.numeric(tail(get_panels_ids("dock"), 1)) + 1)
        ),
        content = paste(
          "This is panel",
          as.character(as.numeric(tail(get_panels_ids("dock"), 1)) + 1)
        ),
        position = list(
          referenceGroup = input[["dock_panel-to-add"]],
          direction = "within"
        )
      )
    )
  })
}

shinyApp(ui, server)
