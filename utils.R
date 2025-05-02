# Simplified function definitions
fns <- list(
  `Layer pipeline` = c(
    "Layer$layer_data",
    "Layer$setup_layer",
    "Layer$compute_aesthetics",
    "Layer$compute_statistic",
    "Layer$map_statistic",
    "Layer$compute_geom_1",
    "Layer$compute_position",
    "Layer$compute_geom_2",
    "Layer$finish_statistics",
    "Layer$draw_geom"
  )
  # `Built layer information` = c("layer_data", "layer_grob")
)

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
