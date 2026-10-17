# Run from scripts/browser. The test runner owns this localhost-only process.
pkgload::load_all("../..", quiet = TRUE, export_all = FALSE)
shiny::runApp(
  PharmaStatsR:::build_diagnostics_app(),
  host = "127.0.0.1", port = 3877, launch.browser = FALSE
)
