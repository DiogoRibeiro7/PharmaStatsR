#' Fit a logistic regression model
#'
#' Convenience wrapper around `stats::glm` for binomial outcomes.
#'
#' @param formula A model formula.
#' @param data A data frame containing the variables.
#' @param ... Additional arguments passed to `stats::glm`.
#'
#' @return A `glm` object.
#' @details The model uses a binomial family. The bundled `outcome` column is
#'   an arbitrary example label, not a defined clinical event. Check outcome
#'   coding, model fit, and possible separation for a real analysis. Numeric
#'   0/1 outcomes model the probability of 1; for a two-level factor outcome,
#'   the second level is the modeled event. The first level of a predictor
#'   factor is the reference under default contrasts. `na.action` in `...`
#'   controls missing model rows as in `glm`; unrelated columns are not part
#'   of the model frame.
#' @export
#'
#' @examples
#' pharma_logistic_regression(outcome ~ dose, data = pharma_sample)
pharma_logistic_regression <- function(formula, data, ...) {
  stats::glm(formula = formula, data = data, family = stats::binomial(), ...)
}
