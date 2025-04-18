library(dockViewR)
library(shiny)
library(bslib)

ui <- page_fillable(
  div(
    class = "d-flex justify-content-center",
    actionButton("insert", "Insert inside panel"),
    selectInput("selinp", "Panel ids", choices = NULL)
  ),
  dock_viewOutput("dock")
)

server <- function(input, output, session) {
  observeEvent(list_panels("dock"), {
    updateSelectInput(
      session = session,
      inputId = "selinp",
      choices = list_panels("dock")
    )
  })

  output$dock <- renderDock_view({
    dock_view(
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
        )
      ),
      theme = "replit"
    )
  })

  output$distPlot <- renderPlot({
    req(input$obs)
    hist(rnorm(input$obs))
  })

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

  observeEvent(input$insert, {
    removeUI(
      selector = sprintf("#%s > *", input$selinp),
      multiple = TRUE
    )
    insertUI(
      selector = sprintf("#%s", input$selinp),
      where = "beforeEnd",
      ui = tagList(
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
      )
    )
  })
}

shinyApp(ui, server)
