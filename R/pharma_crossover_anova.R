#' Analyze a 2x2 crossover design
#'
#' Fits a simple ANOVA model for two-period crossover trials.
#'
#' @param formula A model formula such as `response ~ treatment + period + subject`.
#' @param data A data frame containing the variables in the formula.
#' @param ... Additional arguments passed to `stats::aov`.
#'
#' @return An `aov` object.
#' @export
#'
#' @examples
#' pharma_crossover_anova(response ~ treatment + period + subject, data = pharma_crossover)
pharma_crossover_anova <- function(formula, data, ...) {
  stats::aov(formula = formula, data = data, ...)
}
