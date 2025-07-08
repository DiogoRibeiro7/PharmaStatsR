#!/usr/bin/env Rscript
#' Install required packages and run unit tests
#'
#' This script ensures `devtools` and `testthat` are installed from
#' CRAN before running `devtools::test()`.
#'
#' Usage: Called from setup.sh

required <- c("devtools", "testthat")
missing <- required[!vapply(required, requireNamespace, logical(1), quietly = TRUE)]
if (length(missing)) {
  install.packages(missing, repos = "https://cloud.r-project.org")
}

devtools::test()
