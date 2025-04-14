library(rlang)
library(palmerpenguins)
library(shiny)
library(bslib)
library(shinyAce)
library(listviewer)
library(ggplot2)
library(DT)
if (nzchar(Sys.getenv("WEBR"))) {
  asNamespace("webr")$install(
    "ggtrace",
    repos = c("https://yjunechoe.r-universe.dev", "https://repo.r-wasm.org/")
  )
  check_installed("ggtrace (>= 0.7.4)")
  library(ggtrace)
}

source("utils.R")

# UI layout
ui <- page_sidebar(
  title = "ggplot2 Layer Explorer",
  sidebar = sidebar(
    width = 300,
    radioButtons(
      "selected_function",
      "Function selection:",
      choices = unlist(fns, use.names=FALSE),
      selected = character(0)
    ),
    actionButton("debug_btn", "Debug")
  ),

  layout_column_wrap(
    width = 1/2,
    height = "calc(100vh - 100px)",

    # Code editor card
    card(
      card_header("Code Editor"),
      aceEditor(
        "code_editor",
        value = initial_code,
        mode = "r", theme = "chrome",
        minLines = 1, maxLines = 20, autoScrollEditorIntoView = TRUE
      ),
      div(
        style = "display: flex; justify-content: space-between;",
        actionButton("run_code_btn", "Run Plotting Code", class = "btn-primary"),
        textOutput("code_error_output")
      ),
      div(
        plotOutput("plot_preview", height = "300px")
      )
    ),

    # Right panel with Layer Selector and Inspect
    card(
      card_header("Inspect"),
      div(
        div(
          style = "display: flex; align-items: center; margin-bottom: 10px;",
          span("Layer number (i):", style = "margin-right: 10px;"),
          uiOutput("layer_input_ui", inline = TRUE)
        ),
        aceEditor(
          "function_expr",
          value = '"Click a function from the sidebar to explore ggplot layers"',
          mode = "r", theme = "chrome",
          minLines = 1, maxLines = 20, autoScrollEditorIntoView = TRUE
        ),
        actionButton("run_inspect_expr_btn", "Run expression", class = "btn-sm btn-primary mt-1"),
        actionButton("run_highjack_expr_btn", "Highjack 😈", class = "btn-sm btn-secondary mt-1"),
        uiOutput("function_output_ui")
      )
    )
  )
)

server <- function(input, output, session) {
  # Setup environment
  user_env <- new.env()
  lapply(
    c("grid", "ggplot2", "dplyr"),
    function(pkg) eval(
      rlang::call2("library", pkg, character.only = TRUE),
      envir = user_env
    )
  )

  # Run initial code
  tryCatch({
    eval(parse(text = initial_code), envir = user_env)
    # Set initial value for i
    user_env$i <- length(user_env$p$layers)
  }, error = function(e) {
    # Silent error handling for initialization
  })

  # Reactive for number of layers
  layer_count <- reactiveVal(user_env$i)

  # Reactive for current expression
  current_expr <- reactiveVal("")

  # Dynamic UI for layer input based on number of layers
  output$layer_input_ui <- renderUI({
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

  # Execute user code
  observeEvent(input$run_code_btn, {
    output$code_error_output <- renderText("")
    tryCatch({
      eval(parse(text = input$code_editor), envir = user_env)
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
  })

  # Initialize plot
  output$plot_preview <- renderPlot({
    user_env$p
  })

  # Update i when layer_selector changes
  observeEvent(input$layer_selector, {
    user_env$i <- input$layer_selector
    # Re-run the inspect expression with updated layer selection
    run_inspect_expr(current_expr())
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
        datatable(res)
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

    method_expr <- parse_expr(paste0("ggplot2:::", input$selected_function))
    layer_id_expr <- call2("layer_is", input$layer_selector)
    highjack_expr <- call2(
      "highjack_return",
      x = sym("p"),
      method = method_expr,
      cond = layer_id_expr,
      value = sym("inspect_res"),
      .ns = "ggtrace"
    )
    highjack_res <- tryCatch(
      rlang::eval_tidy(
        local_call(highjack_expr),
        list(inspect_res = inspect_res),
        user_env
      ),
      error = function(e) e
    )
    eval(call2("gguntrace", method_expr, verbose = FALSE, .ns = "ggtrace"), user_env)

    if (is_error(highjack_res)) {
      og_res <- eval(parse_expr(fn_to_expr(input$selected_function)), user_env)
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
        plotOutput("grob_plot_output", height = "300px")
      })
      output$grob_plot_output <- renderPlot({
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
      fn <- input$selected_function
      fn_call <- poorman_styler(fn_to_expr(fn))

      # Update the editor and run the expression
      updateAceEditor(session, "function_expr", value = fn_call)
      current_expr(fn_call)  # Store current expression
      run_inspect_expr(fn_call)
    }
  })

  # Initial function output
  output$function_output_ui <- renderUI({ verbatimTextOutput("text_output") })
  output$text_output <- renderPrint({
    "Click a function from the sidebar to explore ggplot layers"
  })

  observeEvent(input$debug_btn, { browser() })
}

shinyApp(ui, server, options = list(launch.browser = TRUE))
