in_webr <- function() {
  isTRUE(nzchar(Sys.getenv("WEBR")))
}

# Dependencies not picked up by shinylive
if (in_webr()) {
  asNamespace("webr")$install(
    "ggtrace",
    repos = c("https://yjunechoe.r-universe.dev", "https://repo.r-wasm.org/")
  )
  stopifnot(packageVersion("ggtrace") >= package_version("0.7.4"))
  asNamespace("webr")$install(
    "reactR",
    repos = c("https://react-r.r-universe.dev", "https://repo.r-wasm.org/")
  )
  asNamespace("webr")$install("munsell")
}

# Pre-processing
if (!in_webr()) {
  asNamespace("markdown")$mark("about.md", "about.html")
}

library(shiny)
library(ggplot2)
library(grid)
library(dplyr)
library(rlang)
library(palmerpenguins)
library(bslib)
library(bsicons)
library(shinyAce)
library(listviewer)
library(DT)

# some hacks
HAX <- quote({
  assign("setup_data", function(data, params) { data }, envir = Geom)
})
