#' Fit a linear mixed-effects model
#'
#' Provides a wrapper around `lme4::lmer` for mixed-effects modeling.
#'
#' @param formula Model formula including random effects, e.g., `response ~ treatment + (1|subject)`.
#' @param data A data frame containing variables referenced in the formula.
#' @param ... Additional arguments passed to `lme4::lmer`.
#'
#' @return An `lmerMod` object.
#' @export
#'
#' @examples
#' pharma_lmm(response ~ condition + (1|subject), data = pharma_repeated)
pharma_lmm <- function(formula, data, ...) {
  lme4::lmer(formula = formula, data = data, ...)
}
