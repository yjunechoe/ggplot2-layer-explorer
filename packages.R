in_webr <- function() {
  isTRUE(nzchar(Sys.getenv("WEBR")))
}
# Dependencies not picked up by shinylive
if (in_webr()) {
  asNamespace("webr")$install(
    "ggtrace",
    repos = c("https://yjunechoe.r-universe.dev", "https://repo.r-wasm.org/")
  )
  check_installed("ggtrace (>= 0.7.4)")
  asNamespace("webr")$install(
    "reactR",
    repos = c("https://react-r.r-universe.dev", "https://repo.r-wasm.org/")
  )
  asNamespace("webr")$install(
    "munsell",
    repos = c("https://repo.r-wasm.org/")
  )
  )
}
