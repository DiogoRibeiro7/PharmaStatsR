#' Launch the interactive PharmaStatsR dashboard
#'
#' Starts a Shiny dashboard built with `flexdashboard` to explore example
#' datasets included in the package. The dashboard is rendered from an R Markdown
#' file shipped in the package. Launching it requires the optional `rmarkdown`,
#' `flexdashboard`, and `shiny` packages; retrieving its path does not.
#'
#' @param launch Logical. If `TRUE`, the dashboard is launched using
#'   `rmarkdown::run()`. If `FALSE`, the function simply returns the path to the
#'   dashboard file. Defaults to `interactive()` so that tests can retrieve the
#'   path without launching the app.
#'
#' @return Invisibly returns the path to the dashboard Rmd file.
#' @export
#'
#' @examples
#' path <- pharma_dashboard(launch = FALSE)
#' if (interactive()) {
#'   pharma_dashboard()
#' }
pharma_dashboard <- function(launch = interactive()) {
  dash_path <- system.file("dashboard", "pharma_dashboard.Rmd",
    package = "PharmaStatsR"
  )
  if (dash_path == "") {
    stop("Dashboard file not found")
  }
  if (launch) {
    .pharma_launch_dashboard(dash_path)
  }
  invisible(dash_path)
}
