# Simplified function definitions
fns <- list(
  "Layer$layer_data" =
    "Inherit plot data",
  "Layer$setup_layer" =
    "Finalize data to be used for the layer",
  "Layer$compute_aesthetics" =
    "Setup Stat part of layer (scale-transform aesthetics and append `PANEL` and `group` variables)",
  "Layer$compute_statistic" =
    "Compute Stat part of layer",
  "Layer$map_statistic" =
    "Scale-transform computed variables and resolve `after_stat()`",
  "Layer$compute_geom_1" =
    "Setup Geom part of layer",
  "Layer$compute_position" =
    "Apply Position adjustments",
  "Layer$compute_geom_2" =
    "Fill in Geom defaults, apply hard-coded aesthetics, and resolve `after_scale()`",
  "Layer$finish_statistics" =
    "A hook to apply final layer data manipulation",
  "Layer$draw_geom" =
    "Draw the Geom, returning a graphical object (`grob`)"
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



fn_to_expr <- function(fn) {
  parsed <- parse_expr(fn)
  # Built layer information
  if (is.symbol(parsed)) {
    if (grepl(x = fn, "^layer_")) {
      # ggplot2
      expr <- call2(fn, p = sym("p"), i = sym("i"))
    } else {
      # ggtrace
      fn <- paste0("layer_", fn)
      expr <- call2(fn, p = sym("p"), i = sym("i"), .ns = "ggtrace")
    }
  } else {
    # ggproto
    if (!strsplit(fn, "\\$")[[1]][1] %in% getNamespaceExports("ggplot2")) {
      fn <- paste0("ggplot2:::", fn)
    }
    expr <- call2(
      "inspect_return",
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
