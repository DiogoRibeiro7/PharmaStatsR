#' Analyze a Latin square design
#'
#' Fits an ANOVA model for Latin square experiments.
#'
#' @param formula A model formula such as `response ~ treatment + row + column`.
#' @param data A data frame containing the variables in the formula.
#' @param ... Additional arguments passed to `stats::aov`.
#'
#' @return An `aov` object.
#' @export
#'
#' @examples
#' pharma_latin_square_anova(response ~ treatment + row + column, data = pharma_latin_square)
pharma_latin_square_anova <- function(formula, data, ...) {
  stats::aov(formula = formula, data = data, ...)
}
