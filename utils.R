Sys.setenv(
  NO_COLOR = 1
)

# Simplified function definitions
fns <- list(
  "Layer$layer_data" =
    "Inherit plot data",
  "Layer$setup_layer" =
    "Finalize data to be used for the layer",
  "Layer$compute_aesthetics" =
    "Set up aesthetics for the layer and attach `PANEL` and `group` columns",
  "Layer$compute_statistic" =
    "Compute Stat part of layer",
  `└─ Stat$setup_data` = "Set up the data for computing statistics",
  `└─ Stat$compute_layer` = "Apply stat transformation and add computed variables",
  "Layer$map_statistic" =
    "Scale-transform computed variables and resolve `after_stat()`",
  "Layer$compute_geom_1" =
    "Set up Geom part of layer",
  `└─ Geom$setup_data` = "Set up the data for computing geometries",
  "Layer$compute_position" =
    "Apply Position adjustments",
  `└─ Position$setup_data` = "Set up the data for position adjustments",
  `└─ Position$compute_layer` = "Apply position adjustments",
  "Layer$compute_geom_2" =
    "Implements Layer$compute_geom_2",
  `└─ Geom$use_defaults` = "Finalize aesthetics for the geom (ex: resolve `after_scale()`)",
  "Layer$finish_statistics" =
    "Calls Stat$finish_layer",
  `└─ Stat$finish_layer` = "A hook to apply final layer data manipulation",
  "Layer$draw_geom" =
    "Calls Geom$draw_layer",
  `└─ Geom$draw_layer` = "Draw the Geom, returning a graphical object (`grob`)"
)

fns_info <- lapply(seq_along(fns), \(i) {
  span(
    style = "display: inline-flex;",
    span(names(fns)[i], style = "padding-right: 3px;"),
    tooltip(
      bsicons::bs_icon("question-circle"),
      fns[[i]],
      placement = "right"
    )
  )
})

prune_fn <- function(x) {
  gsub(x = x, "^.* ", "")
}

resolve_fn <- function(fn, user_env) {
  fn <- prune_fn(fn)
  if (grepl(x = fn, "^Layer")) {
    return(paste0("ggplot2:::", fn))
  }
  splt <- strsplit(fn, "\\$")[[1]]
  obj <- splt[1]
  mthd <- splt[2]
  ggproto_obj <- eval(expr(p$layers[[i]][[!!tolower(obj)]]), user_env)
  which_ggproto <- names(which.max(sapply(
    get_method_inheritance(ggproto_obj),
    \(x) mthd %in% x
  )))
  paste(which_ggproto, mthd, sep = "$")
}

fn_to_expr <- function(fn, type = c("output", "input"), user_env) {
  user_env <- eval.parent(quote(user_env))
  fn <- prune_fn(fn)
  parsed <- parse_expr(fn)
  # Built layer information
  if (is.symbol(parsed)) {
    if (grepl(x = fn, "^layer_")) {
      # ggplot2 (ex: layer_data())
      expr <- call2(fn, p = sym("p"), i = sym("i"))
    } else {
      # ggtrace (ex: layer_after_stat())
      fn <- paste0("layer_", fn)
      expr <- call2(fn, p = sym("p"), i = sym("i"), .ns = "ggtrace")
    }
  } else {
    # ggproto
    fn <- resolve_fn(fn, user_env)
    expr <- call2(
      paste0("inspect_", resolve_inspect_type(type)),
      x = sym("p"),
      method = parse_expr(fn),
      cond = call2("layer_is", sym("i"))
    )
  }
  deparse1(expr)
}

local_call <- function(expr) {
  exprs <- if (is.character(expr)) {
    parse_exprs(expr)
  } else {
    if (rlang::is_bare_list(expr)) {
      expr
    } else {
      list(expr)
    }
  }
  call2("local", call2("{", !!!exprs))
}

poorman_styler <- function(expr) {
  gsub(x = expr, ",", ",\n ") |>
    gsub(x = _, "^(\\w+\\()(.+)(\\))$", "\\1\n  \\2\n\\3\n")
}

is.roundable <- function(x) {
  is.double(x) &&
    !ggplot2:::is_mapped_discrete(x) &&
    !identical(x, floor(x))
}

radioInlinedButtons <- function(inputId, label, ..., extras = NULL) {
  div(
    div(
      style = "display: flex; align-items: center;",
      tags$label(
        label,
        style = "margin-right: 10px; margin-bottom: 1rem;"
      ),
      div(
        radioButtons(
          inputId = inputId,
          label = NULL,
          inline = TRUE,
          width = "auto",
          ...
        )
      ),
      extras
    ),
  )
}

resolve_inspect_type <- function(x = c("output", "input")) {
  x <- match.arg(x)
  c("output" = "return", "input" = "args")[[x]]
}

show_sublayer_methods <- function(x) {
  methods_data <- list(
    Stat = get_method_inheritance(x$stat),
    Geom = get_method_inheritance(x$geom),
    Position = get_method_inheritance(x$position)
  )
  methods_table <- do.call(rbind, lapply(names(methods_data), function(main_class) {
    do.call(rbind, lapply(names(methods_data[[main_class]]), function(sub_class) {
      data.frame(
        Class = main_class,
        Subclasses = sub_class,
        Methods = paste(methods_data[[main_class]][[sub_class]], collapse = ", ")
      )
    }))
  }))
  methods_table$Class[duplicated(methods_table$Class)] <- ""
  methods_table
}

compare_input_output <- function(input, output) {
  input_data <- intersect(c("data", "plot_data"), names(input))
  input <- input[[input_data]]
  both_df <- is.data.frame(input) && is.data.frame(output)
  waldo::compare(
    input, output,
    x_arg = paste0("input$", input_data), y_arg = "output",
    max_diffs = if (both_df) Inf else 2,
    ignore_attr = "row.names",
    list_as_map = both_df
  )
}
