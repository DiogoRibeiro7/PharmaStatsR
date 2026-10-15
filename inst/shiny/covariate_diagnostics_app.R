# Standalone launcher; the exported entry point is run_diagnostics_app().

if (!requireNamespace("PharmaStatsR", quietly = TRUE)) {
  stop("Install PharmaStatsR before running this app script.")
}

app <- PharmaStatsR:::build_diagnostics_app()
shiny::runApp(app)
