#!/usr/bin/env Rscript

# Run the package's unit tests with a small, explicit dependency set. Optional
# modelling backends are covered by tests when installed, and guarded otherwise.
required <- c("devtools", "testthat", "broom", "openssl", "gsDesign")
missing <- required[!vapply(required, requireNamespace, logical(1), quietly = TRUE)]

if (length(missing) > 0L && identical(Sys.getenv("SKIP_R_INSTALL"), "1")) {
  stop("Required packages are missing: ", paste(missing, collapse = ", "))
}
if (length(missing) > 0L) {
  install.packages(missing, repos = "https://cloud.r-project.org")
}

still_missing <- required[!vapply(required, requireNamespace, logical(1), quietly = TRUE)]
if (length(still_missing) > 0L) {
  stop("Unable to install required packages: ", paste(still_missing, collapse = ", "))
}

devtools::test(stop_on_failure = TRUE)
