# Dependencies not picked up by shinylive
if (nzchar(Sys.getenv("WEBR"))) {
  asNamespace("webr")$install(
    "ggtrace",
    repos = c("https://yjunechoe.r-universe.dev", "https://repo.r-wasm.org/")
  )
  check_installed("ggtrace (>= 0.7.4)")
  asNamespace("webr")$install(
    "reactR",
    repos = c("https://react-r.r-universe.dev", "https://repo.r-wasm.org/")
  )
}
