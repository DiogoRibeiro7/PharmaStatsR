#' Perform a two-sample t-test via Python's SciPy
#'
#' Uses `reticulate` to call `scipy.stats.ttest_ind` for performing a
#' two-sample t-test. This demonstrates integration with Python from R.
#' The optional R package `reticulate` and the Python module `scipy.stats`
#' must be available. A missing backend errors rather than running an R test.
#' With `equal_var = TRUE` SciPy uses the pooled-variance test; `FALSE`
#' requests Welch's test.
#'
#' @param x Numeric vector of observations for group 1.
#' @param y Numeric vector of observations for group 2.
#' @param equal_var Logical indicating whether to assume equal variance.
#'
#' @return A list with the test statistic and p-value.
#' @export
#'
#' @examples
#' if (requireNamespace("reticulate", quietly = TRUE) &&
#'   reticulate::py_available(initialize = FALSE) &&
#'   reticulate::py_module_available("scipy.stats")) {
#'   pharma_scipy_ttest(c(1, 2, 4, 7, 8), c(3, 5, 9, 10, 12))
#' }
pharma_scipy_ttest <- function(x, y, equal_var = TRUE) {
  if (!.pharma_reticulate_available()) {
    stop("Package 'reticulate' is required for pharma_scipy_ttest(). ",
         "Install it with install.packages('reticulate').", call. = FALSE)
  }
  if (!.pharma_scipy_available()) {
    stop("Python module 'scipy.stats' is required for ",
         "pharma_scipy_ttest(). Install it in reticulate's Python environment ",
         "with python -m pip install scipy.", call. = FALSE)
  }
  scipy <- reticulate::import("scipy.stats")
  res <- scipy$ttest_ind(x, y, equal_var = equal_var)
  list(statistic = res$statistic, p.value = res$pvalue)
}

.pharma_reticulate_available <- function() {
  requireNamespace("reticulate", quietly = TRUE)
}

.pharma_scipy_available <- function() {
  # Interpreter discovery may fail before a module check can return FALSE.
  tryCatch(reticulate::py_module_available("scipy.stats"),
           error = function(e) FALSE)
}
