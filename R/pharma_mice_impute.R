#' Perform multiple imputation using mice
#'
#' Convenience wrapper around `mice::mice` for creating multiply imputed
#' datasets. Requires the optional **mice** package.
#'
#' @param data A data frame with missing values.
#' @param m Number of imputations to perform. Defaults to 5.
#' @param ... Additional arguments passed to `mice::mice`.
#'
#' @return A `mids` object from the **mice** package.
#' @export
#'
#' @examples
#' if (requireNamespace("mice", quietly = TRUE)) {
#'   dat <- pharma_sample
#'   dat$response[1] <- NA
#'   pharma_mice_impute(dat, m = 2, maxit = 1)
#' }
pharma_mice_impute <- function(data, m = 5, ...) {
  if (!.pharma_mice_available()) {
    stop(
      "Optional package 'mice' is required for pharma_mice_impute(). Install it with install.packages('mice').",
      call. = FALSE
    )
  }
  mice::mice(data, m = m, printFlag = FALSE, ...)
}

.pharma_mice_available <- function() {
  requireNamespace("mice", quietly = TRUE)
}
