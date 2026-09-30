.pharma_dashboard_available <- function(package) {
  requireNamespace(package, quietly = TRUE)
}

.pharma_dashboard_run <- function(path) {
  rmarkdown::run(path)
}

.pharma_launch_dashboard <- function(path) {
  packages <- c("rmarkdown", "flexdashboard", "shiny")
  missing <- packages[!vapply(packages, .pharma_dashboard_available, logical(1))]
  if (length(missing) > 0L) {
    stop(
      "Launching a dashboard requires optional packages: ",
      paste(missing, collapse = ", "), ". Install with install.packages(c(",
      paste(sprintf('"%s"', missing), collapse = ", "), ")).",
      call. = FALSE
    )
  }
  .pharma_dashboard_run(path)
}
