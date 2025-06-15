#' Conduct a one-way ANOVA
#'
#' Provides a thin wrapper around `stats::aov` for comparing means across groups.
#'
#' @param formula A model formula specifying the outcome and group.
#' @param data A data frame containing the variables in the formula.
#' @param ... Additional arguments passed to `stats::aov`.
#'
#' @return An object of class `aov`.
#' @export
#'
#' @examples
#' pharma_anova(response ~ treatment, data = pharma_sample)
pharma_anova <- function(formula, data, ...) {
  stats::aov(formula = formula, data = data, ...)
}
