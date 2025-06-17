#' Conduct a factorial ANOVA
#'
#' Wrapper around `stats::aov` for multi-factor experimental designs.
#'
#' @param formula A model formula specifying factors and interactions.
#' @param data A data frame containing the variables in the model.
#' @param ... Additional arguments passed to `stats::aov`.
#'
#' @return An `aov` object.
#' @export
#'
#' @examples
#' pharma_factorial_anova(response ~ treatment * dose, data = pharma_sample)
pharma_factorial_anova <- function(formula, data, ...) {
  stats::aov(formula = formula, data = data, ...)
}
