library(dockViewR)
library(shiny)
library(bslib)

ui <- page_fillable(
  div(
    class = "d-flex justify-content-center",
    actionButton("insert", "Insert inside panel"),
    selectInput("selinp", "Panel ids", choices = NULL)
  ),
  dockViewOutput("dock")
)

server <- function(input, output, session) {
  exportTestValues(
    n_panels = length(get_panels_ids("dock"))
  )

  observeEvent(get_panels_ids("dock"), {
    updateSelectInput(
      session = session,
      inputId = "selinp",
      choices = get_panels_ids("dock")
    )
  })

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
      selector = sprintf("#dock-%s > *", input$selinp),
      multiple = TRUE
    )
    insertUI(
      selector = sprintf("#dock-%s", input$selinp),
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
