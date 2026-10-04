#' Fit a linear mixed-effects model
#'
#' Provides a wrapper around `lme4::lmer` for mixed-effects modeling. The
#' function validates its inputs and ensures that `lme4` is installed
#' before fitting the model.
#'
#' @param formula Model formula including random effects, e.g.,
#'   `response ~ treatment + (1|subject)`.
#' @param data A data frame containing variables referenced in the formula.
#' @param ... Additional arguments passed to `lme4::lmer`.
#'
#' @return An `lmerMod` object.
#' @details `lmer` uses REML by default. A random-intercept formula
#'   `response ~ condition + (1 | subject)` estimates a common condition
#'   contrast with subject-specific baselines. Use `predict(fit, re.form = NA)`
#'   for population predictions; conditional predictions include estimated
#'   subject effects. Missing-row selection and singularity or convergence
#'   diagnostics are delegated to `lme4`. A returned fit is not proof of
#'   adequate grouping, normality, or model validity.
#' @export
#'
#' @examples
#' if (requireNamespace("lme4", quietly = TRUE)) {
#' pharma_lmm(response ~ condition + (1 | subject), data = pharma_repeated)
#' }

pharma_lmm <- function(formula, data, ...) {
  validate_inputs(data, formula)
  .pharma_require_optional("lme4", "pharma_lmm")
  lme4::lmer(formula = formula, data = data, ...)
}
