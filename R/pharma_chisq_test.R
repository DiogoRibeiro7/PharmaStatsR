#' Conduct a chi-square test
#'
#' Provides a convenience wrapper around `stats::chisq.test` for contingency
#' tables commonly used in pharmaceutical analyses.
#'
#' @param x A matrix or table of counts.
#' @param ... Additional arguments passed to `stats::chisq.test`.
#'
#' @return A `htest` object from `stats::chisq.test`.
#' @export
#'
#' @examples
#' pharma_chisq_test(matrix(c(12, 5, 7, 9), nrow = 2))
pharma_chisq_test <- function(x, ...) {
  stats::chisq.test(x, ...)
}
