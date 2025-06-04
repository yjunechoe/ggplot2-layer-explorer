source("packages.R")
source("utils.R")
source("plot-examples.R")

# UI layout
ui <- page_navbar(
  title = "ggplot2 Layer Explorer",
  theme = bs_theme(),
  # Main Explorer tab
  nav_panel(
    title = "Explorer",
    page_sidebar(
      sidebar = sidebar(
        width = 350,
        radioButtons(
          "selected_function",
          "Method selection:",
          choiceNames = fns_info,
          choiceValues = names(fns)
        ),
        if (!in_webr()) { actionButton("debug_btn", "Debug") }
      ),

      layout_column_wrap(
        width = 1/2,
        height = "calc(100vh - 100px)",

        # Code editor card
        card(
          card_header("Define plot"),
          div(
            div(
              style = "margin-bottom: -1rem;",
              radioInlinedButtons(
                inputId = "plot_selector",
                label = "Use a pre-defined plot:",
                choices = seq_along(plots)
              )
            ),
            hr(style = "margin: 1rem 0;"),
            aceEditor(
              "code_editor",
              value = plots$plot1,
              mode = "r", theme = "chrome", fontSize = 14,
              minLines = 5, maxLines = 20, autoScrollEditorIntoView = TRUE
            ),
            div(
              style = "display: flex; justify-content: space-between;",
              actionButton("run_code_btn", "Run Plotting Code", class = "btn-primary"),
              textOutput("code_error_output")
            ),
            div(
              plotOutput("plot_preview", height = "300px")
            )
          )
        ),

        # Right panel with Layer Selector and Inspect
        card(
          card_header("Explore method"),
          div(
            div(
              style = "display: flex; align-items: center; margin-bottom: -1rem;",
              span("Layer number (i):", style = "margin-right: 10px;"),
              uiOutput("layer_id", inline = TRUE, style = "margin-bottom: -1rem;"),
              code(textOutput("selected_layer_fn"), style = "margin-left: 1rem;"),
              actionButton(
                "show_layer_methods", "Show layer info",
                style = "margin-left: 1rem;",
                class = "btn-sm btn-primary mt-1"
              )
            ),
            div(
              style = "margin-top: 1.5rem; margin-bottom: -1rem;",
              radioInlinedButtons(
                inputId = "inspect_type",
                label = "Inspect:",
                choices = c("input", "output"),
                extras = actionButton(
                  "show_input_output_diff", "Show data diff",
                  style = "margin: 1rem;",
                  class = "btn-sm btn-primary mt-1"
                )
              )
            ),
            hr(style = "margin: 1rem 0;"),
            aceEditor(
              "function_expr",
              value = "",
              mode = "r", theme = "chrome", fontSize = 14,
              minLines = 5, maxLines = 20, autoScrollEditorIntoView = TRUE
            ),
            actionButton("run_inspect_expr_btn", "Run expression", class = "btn-sm btn-primary mt-1"),
            actionButton("run_highjack_expr_btn", "Highjack plot 😈", class = "btn-sm btn-secondary mt-1"),
            uiOutput("function_output_ui")
          )
        )
      )
    )
  ),

  # About tab
  nav_panel(
    title = "About",
    page_fillable(
      padding = 20,
      div(
        style = "max-width: 900px; margin: 0 auto;",
        card(
          card_body(
            tags$style(HTML("
              pre code {
                padding: 0px;
              }
              li {
                margin-bottom: .2rem;
              }
            ")),
            includeHTML("about.html")
          )
        )
      )
    )
  )
)

server <- function(input, output, session) {
  # Setup environment
  user_env <- new.env()
  lapply(
    c("ggtrace", "grid", "ggplot2", "dplyr"),
    function(pkg) eval(
      call2("library", pkg, character.only = TRUE),
      envir = user_env
    )
  )

  # Run initial code
  tryCatch({
    eval(parse(text = plots$plot1), envir = user_env)
    # Set initial value for i
    user_env$i <- 1
    lockBinding("i", user_env)
  }, error = function(e) {
    # Silent error handling for initialization
  })

  # Initialize reactive for number of layers
  layer_count <- reactiveVal(length(user_env$p$layers))
  # Initialize reactive for current expression
  current_expr <- reactiveVal("")

  # Dynamic UI for layer input based on number of layers
  output$layer_id <- renderUI({
    nlayers <- layer_count()
    numericInput(
      "layer_selector",
      label = NULL,
      value = 1,
      min = 1,
      max = max(1, nlayers),
      step = 1,
      width = "50px"
    )
  })

  # Execute user plotting code
  run_code_editor <- function(code_text) {
    output$code_error_output <- renderText("")
    tryCatch({
      eval(parse(text = gsub(x = code_text, "\r", "")), envir = user_env)
      if (!exists("p", envir = user_env) || !inherits(user_env$p, "ggplot")) {
        stop("A ggplot object `p` must exist in the environment")
      }

      # Update plot and layer count after running code
      num_layers <- length(user_env$p$layers)
      layer_count(num_layers)
      output$plot_preview <- renderPlot({ user_env$p })

      # Re-run the inspect expression with updated environment
      run_inspect_expr(current_expr())
    }, error = function(e) {
      output$code_error_output <- renderText(paste("Error:", e$message))
    })
  }

  # Refresh and execute inspect code
  update_and_run_inspect_expr <- function(fn = input$selected_function,
                                          inspect_type = input$inspect_type) {
    fn_call <- fn_to_expr(fn, inspect_type)
    updateAceEditor(session, "function_expr", poorman_styler(fn_call))
    current_expr(fn_call)
    run_inspect_expr(fn_call)
  }

  observeEvent(input$run_code_btn, {
    run_code_editor(input$code_editor)
  })

  observeEvent(input$plot_selector, {
    # Update and run plot expression
    selected_plot_code <- plots[[as.integer(input$plot_selector)]]
    updateAceEditor(session, "code_editor", value = selected_plot_code)
    run_code_editor(selected_plot_code)
    # Reset layer ID
    updateNumericInput(session, "layer_selector", value = 1)
    update_i(1L)
    # Update and run inspect expression
    update_and_run_inspect_expr()
  })

  # Initialize plot
  output$plot_preview <- renderPlot({
    user_env$p
  })

  cur_layer <- function() {
    evalq(p$layers[[i]], user_env)
  }
  update_i <- function(value) {
    # Update value in env
    unlockBinding("i", user_env)
    user_env$i <- value
    lockBinding("i", user_env)
    # Update display
    layer_fn <- deparse1(cur_layer()$constructor[1])
    output$selected_layer_fn <- renderText({ layer_fn })
  }

  # Update i when layer_selector changes
  observeEvent(input$layer_selector, {
    update_i(input$layer_selector)
    # Update and run inspect expression
    update_and_run_inspect_expr()
  })

  # Update expression when inspect_type changes
  observeEvent(input$inspect_type, {
    # Update and run inspect expression
    update_and_run_inspect_expr()
  })

  # Run data diff button
  observeEvent(input$show_input_output_diff, {
    input_call <- fn_to_expr(input$selected_function, "input")
    output_call <- fn_to_expr(input$selected_function, "output")
    input_data <- tryCatch(
      eval(local_call(input_call), envir = user_env),
      error = function(e) e
    )
    output_data <- tryCatch(
      eval(local_call(output_call), envir = user_env),
      error = function(e) e
    )
    comparison <- compare_input_output(input_data, output_data)
    output$diff_result <- renderPrint({ comparison })
    showModal(
      modalDialog(
        title = "Data diff",
        verbatimTextOutput("diff_result"),
        easyClose = TRUE,
        footer = NULL,
        size = "xl",
        open = TRUE
      )
    )
  })

  # Layer methods info button
  observeEvent(input$show_layer_methods, {
    thelayer <- cur_layer()
    output$layer_constructor_text <- renderText({
      deparse1(thelayer$constructor)
    })
    layer_methods <- show_sublayer_methods(thelayer)
    showModal(
      modalDialog(
        title = "Layer information",
        div(
          verbatimTextOutput("layer_constructor_text"),
          renderTable(
            layer_methods,
            striped = TRUE,
            hover = TRUE,
            bordered = TRUE,
            spacing = 'xs',
            width = '100%'
          )
        ),
        easyClose = TRUE,
        footer = NULL,
        size = "xl",
        open = TRUE
      )
    )
  })

  run_inspect_expr <- function(expr) {
    if (!nzchar(expr)) return(NULL)
    res <- tryCatch(
      eval(local_call(expr), envir = user_env),
      error = function(e) e
    )
    if (inherits(res, "grob")) {
      output$function_output_ui <- renderUI({
        tagList(
          plotOutput("grob_plot_output", height = "300px"),
          reactjsonOutput("str_output")
        )
      })
      output$grob_plot_output <- renderPlot({
        grid.newpage()
        pushViewport(viewport())
        grid.draw(res)
      })
      output$str_output <- renderReactjson({
        reactjson(
          jsonlite::toJSON(unclass(res), force = TRUE),
          collapsed = 1,
          enableClipboard = FALSE,
          displayObjectSize = FALSE, displayDataTypes = FALSE,
          onEdit = FALSE, onAdd = FALSE, onDelete = FALSE, onSelect = FALSE
        )
      })
    } else if (inherits(res, "data.frame")) {
      output$function_output_ui <- renderUI({
        DTOutput("table_output")
      })
      output$table_output <- renderDT({
        res |>
          datatable(
            extensions = "Scroller",
            options = list(
              dom = "t",
              deferRender = TRUE,
              scrollY = 400,
              scroller = TRUE
            ),
            fillContainer = TRUE
          ) |>
          formatRound(which(sapply(res, is.roundable), 2))
      })
    } else {
      output$function_output_ui <- renderUI({
        verbatimTextOutput("text_output")
      })
      output$text_output <- renderPrint({
        res
      })
    }
  }

  run_highjack_expr <- function(expr) {
    if (!nzchar(expr)) return(NULL)
    inspect_res <- tryCatch(
      eval(local_call(expr), envir = user_env),
      error = function(e) e
    )

    method_expr <- parse_expr(resolve_fn(input$selected_function, user_env))
    layer_id_expr <- call2("layer_is", input$layer_selector)
    highjack_expr <- call2(
      paste0("highjack_", resolve_inspect_type(input$inspect_type)),
      x = sym("p"),
      method = method_expr,
      cond = layer_id_expr,
      value = sym("new_value")
    )
    highjack_res <- tryCatch(
      eval_tidy(
        local_call(highjack_expr),
        list(new_value = inspect_res),
        user_env
      ),
      error = function(e) e
    )
    untrace_expr <- call2("gguntrace", method_expr, .ns = "ggtrace")
    eval(call2("suppressMessages", untrace_expr), user_env)

    if (is_error(highjack_res)) {
      fn_call <- fn_to_expr(input$selected_function, input$inspect_type)
      og_res <- eval(parse_expr(fn_call), user_env)
      output$function_output_ui <- renderUI({
        verbatimTextOutput("text_output")
      })
      output$text_output <- renderPrint({
        cat("! Error: ", highjack_res$message, "\n")
        cat("i Check the data type carefully\n")
        cat(format(
          waldo::compare(
            og_res, inspect_res, list_as_map = TRUE,
            x_arg = "Original value", y_arg = "Highjacked value"
          )
        ))
      })
      return(NULL)
    }
    if (!inherits(highjack_res, "ggtrace_highjacked")) {
      output$text_output <- renderPrint({
        stop("Expression failed to generate a highjacked ggplot")
      })
    } else {
      output$function_output_ui <- renderUI({
        div(
          style = "font-size: 0.8rem",
          verbatimTextOutput("highjack_expr_putput"),
          plotOutput("highjack_plot_output", height = "300px")
        )
      })
      output$highjack_expr_putput <- renderText({
        names(highjack_expr)[names(highjack_expr) != "value"] <- ""
        deparse1(highjack_expr)
      })
      output$highjack_plot_output <- renderPlot({
        grid.newpage()
        pushViewport(viewport())
        grid.draw(highjack_res)
      })
    }
  }

  # Run function expressions
  observeEvent(input$run_inspect_expr_btn, {
    current_expr(input$function_expr)
    run_inspect_expr(input$function_expr)
  })
  observeEvent(input$run_highjack_expr_btn, {
    current_expr(input$function_expr)
    run_highjack_expr(input$function_expr)
  })

  # Handle radio button selection
  observeEvent(input$selected_function, {
    if (!is.null(input$selected_function)) {
      # Update and run inspect expression
      update_and_run_inspect_expr()
    }
  })

  # Initial function output
  output$function_output_ui <- renderUI({ verbatimTextOutput("text_output") })
  output$text_output <- renderPrint({
    cat(input$function_expr)
  })

  if (!in_webr()) {
    observeEvent(input$debug_btn, { browser() })
  }

}

shinyApp(ui, server, options = list(launch.browser = TRUE))
