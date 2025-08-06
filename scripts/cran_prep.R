check_pkg_for_cran <- function() {
  if (any(devtools::document())) {
    stop("Documentation is out of date. Run scripts/style_and_doc.sh first.")
  }
  desc <- read.dcf("DESCRIPTION")
  required <- c("Title", "Description", "Author", "Maintainer")
  if (any(is.na(desc[, required]))) {
    stop("DESCRIPTION is missing required fields")
  }
  check_results <- devtools::check(cran = TRUE)
  if (length(check_results$errors) > 0 || length(check_results$warnings) > 0) {
    stop("CRAN check failed with errors or warnings")
  }
  if (!all(tools::checkVignettes())) {
    stop("Vignette check failed")
  }
  cat("Package passes CRAN checks!\n")
}
