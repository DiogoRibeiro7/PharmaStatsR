#' Perform a two-sample t-test via Python's SciPy
#'
#' Uses `reticulate` to call `scipy.stats.ttest_ind` for performing a
#' two-sample t-test. This demonstrates integration with Python from R.
#'
#' @param x Numeric vector of observations for group 1.
#' @param y Numeric vector of observations for group 2.
#' @param equal_var Logical indicating whether to assume equal variance.
#'
#' @return A list with the test statistic and p-value.
#' @export
#'
#' @examples
#' if (reticulate::py_available(initialize = FALSE)) {
#'   pharma_scipy_ttest(rnorm(20), rnorm(20))
#' }
pharma_scipy_ttest <- function(x, y, equal_var = TRUE) {
  if (!requireNamespace("reticulate", quietly = TRUE)) {
    stop("Package 'reticulate' is required for pharma_scipy_ttest()")
  }
  scipy <- reticulate::import("scipy.stats")
  res <- scipy$ttest_ind(x, y, equal_var = equal_var)
  list(statistic = res$statistic, p.value = res$pvalue)
}
