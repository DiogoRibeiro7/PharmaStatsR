#' Fit a logistic regression model
#'
#' Convenience wrapper around `stats::glm` for binomial outcomes.
#'
#' @param formula A model formula.
#' @param data A data frame containing the variables.
#' @param ... Additional arguments passed to `stats::glm`.
#'
#' @return A `glm` object.
#' @export
#'
#' @examples
#' pharma_logistic_regression(outcome ~ dose, data = pharma_sample)
pharma_logistic_regression <- function(formula, data, ...) {
  stats::glm(formula = formula, data = data, family = stats::binomial(), ...)
}
