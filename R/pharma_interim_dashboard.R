#' Launch a real-time interim monitoring dashboard
#'
#' Starts a minimal Shiny dashboard showing simulated enrollment over time.
#' If `launch` is `TRUE`, the dashboard is started using `rmarkdown::run()`;
#' otherwise the path to the dashboard file is returned. The dashboard
#' template is stored in `inst/dashboard/pharma_interim_dashboard.Rmd`.
#'
#' @param launch Logical. Whether to launch the dashboard.
#'
#' @return Invisibly returns the path to the dashboard Rmd file.
#' @export
#'
#' @examples
#' path <- pharma_interim_dashboard(launch = FALSE)
#' if (interactive()) {
#'   pharma_interim_dashboard()
#' }
pharma_interim_dashboard <- function(launch = interactive()) {
  dash_path <- system.file("dashboard", "pharma_interim_dashboard.Rmd",
    package = "PharmaStatsR"
  )
  if (dash_path == "") {
    stop("Dashboard file not found")
  }
  if (launch) {
    rmarkdown::run(dash_path)
  }
  invisible(dash_path)
}
