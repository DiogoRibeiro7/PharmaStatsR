#' Open a simulated enrollment dashboard
#'
#' Opens an example Shiny dashboard that draws random enrollment counts when
#' rendered. It does not read study data, track live enrollment, calculate
#' interim statistics, or apply a monitoring rule. If `launch` is `TRUE`,
#' `rmarkdown::run()` opens the bundled R Markdown file; otherwise the path
#' to that file is returned.
#'
#' @param launch Logical. Whether to open the example dashboard.
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
