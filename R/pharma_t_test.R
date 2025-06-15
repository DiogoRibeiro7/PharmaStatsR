#' Conduct a two-sample t-test
#'
#' Provides a simple wrapper around `stats::t.test` for comparing two numeric
#' samples. The function returns the full result from `stats::t.test` so users
#' can inspect p-values and confidence intervals.
#'
#' @param x Numeric vector of observations from the first group.
#' @param y Numeric vector of observations from the second group.
#' @param ... Additional arguments passed to `stats::t.test`.
#'
#' @return A `htest` object produced by `stats::t.test`.
#' @export
#'
#' @examples
#' pharma_t_test(rnorm(10), rnorm(10))
pharma_t_test <- function(x, y, ...) {
  stats::t.test(x, y, ...)
}
