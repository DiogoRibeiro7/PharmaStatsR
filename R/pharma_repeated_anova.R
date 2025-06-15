#' Conduct a repeated measures ANOVA
#'
#' Simplifies calls to `stats::aov` for repeated measures designs.
#'
#' @param formula A model formula specifying within-subject error terms, e.g.,
#'   `response ~ condition + Error(subject)`.
#' @param data A data frame containing the variables in the formula.
#' @param ... Additional arguments passed to `stats::aov`.
#'
#' @return An `aov` object.
#' @export
#'
#' @examples
#' pharma_repeated_anova(response ~ condition + Error(subject), data = pharma_repeated)
pharma_repeated_anova <- function(formula, data, ...) {
  stats::aov(formula = formula, data = data, ...)
}
