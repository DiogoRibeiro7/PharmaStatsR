#' Inspect residuals and fit statistics from an ANCOVA fit
#'
#' Use the saved additive linear model from [pharma_ancova()] to extract fitted
#' values, residuals, observation counts, residual degrees of freedom,
#' deviance and log-likelihood. These methods delegate to the corresponding
#' native methods without refitting or changing the fitted result.
#'
#' @param object A result returned by [pharma_ancova()], including a saved
#'   result loaded with `readRDS()`. Its additive `model` must remain an `lm`.
#' @param REML Use restricted maximum likelihood for [stats::logLik()] when
#'   `TRUE`. The default is maximum likelihood (`FALSE`), as for `lm`.
#' @param ... Arguments forwarded to the corresponding native method. For
#'   [stats::residuals()], `type` selects `"working"` (default), `"response"`,
#'   `"deviance"`, `"pearson"` or `"partial"`. Native validation, warnings and
#'   output attributes are retained.
#'
#' @return `fitted()` and ordinary `residuals()` calls return named numeric
#'   vectors in the selected analysis rows' stored order. Partial residuals
#'   form a matrix with one column per model term. `nobs()` returns the number
#'   of fitted rows, `df.residual()` the additive model's residual degrees of
#'   freedom, and `deviance()` its residual sum of squares (weighted when
#'   precision weights were used). `logLik()` returns the native `logLik`
#'   object, including its `df`, `nobs` and `nall` attributes.
#' @details
#' Default residuals are the response minus the fitted additive mean. For
#' weighted fits, `type = "pearson"` and `type = "deviance"` multiply these
#' raw residuals by the square root of the precision weights; they do not
#' divide by a residual standard deviation or adjust for leverage. Partial
#' residuals follow the native linear-model term convention. The aliases
#' `fitted.values()` and `resid()` work through the same registrations.
#'
#' Only retained analysis rows are returned. `nobs()` counts those rows, not
#' the original input rows or the sum of precision weights. With `n` rows and
#' additive rank `p`, `df.residual()` is `n - p`. The separate interaction
#' diagnostic is not used. For standardized residuals, leverage and Cook's
#' distances, use [pharma_model_diagnostics()] on `object$model`.
#'
#' Likelihoods use the native Gaussian `lm` likelihood, including precision
#' weight constants. The ML variance estimate uses residual sum of squares
#' divided by `n`, unlike the residual variance in `summary()`, which divides
#' by `n - p`. The likelihood's parameter count includes the error variance.
#' For `REML = TRUE`, the native likelihood's `nobs` attribute is `n - p`;
#' this does not change `nobs(object)` or the stored fitted model.
#'
#' [stats::AIC()] and [stats::BIC()] work through `logLik()` and use ML by
#' default; `AIC()` also supports its native `k` penalty and multiple models.
#' Compare criteria only for the same observations and response scale, with
#' comparable likelihood and weighting assumptions. Do not compare REML
#' likelihoods across different fixed-effect designs. These accessors retain
#' native comparison checks; they do not establish comparison validity or
#' model adequacy.
#'
#' Existing saved ANCOVA results work after loading PharmaStatsR. The original
#' training data need not exist. No random numbers are drawn, and the saved
#' adjusted means, interaction fit, coefficients and predictions are unchanged.
#' @examples
#' trial <- data.frame(
#'   response = c(11, 11, 13, 17, 14, 16, 20, 26),
#'   treatment = factor(rep(c("A", "B"), each = 4)),
#'   baseline = rep(0:3, 2), precision = 1:8
#' )
#' fit <- pharma_ancova(response ~ treatment + baseline, trial,
#'   weights = precision
#' )
#' fitted(fit)
#' residuals(fit)
#' residuals(fit, type = "pearson")
#' c(n = nobs(fit), residual_df = df.residual(fit), SSE = deviance(fit))
#' logLik(fit)
#' logLik(fit, REML = TRUE)
#' AIC(fit)
#' BIC(fit)
#' @seealso [coef.pharma_ancova()], [summary.pharma_ancova()],
#'   [stats::residuals()], [stats::logLik()], [stats::AIC()]
#' @export
residuals.pharma_ancova <- function(object, ...) {
  stats::residuals(ancova_additive_model(object), ...)
}

#' @rdname residuals.pharma_ancova
#' @export
fitted.pharma_ancova <- function(object, ...) {
  stats::fitted(ancova_additive_model(object), ...)
}

#' @rdname residuals.pharma_ancova
#' @export
nobs.pharma_ancova <- function(object, ...) {
  stats::nobs(ancova_additive_model(object), ...)
}

#' @rdname residuals.pharma_ancova
#' @export
df.residual.pharma_ancova <- function(object, ...) {
  stats::df.residual(ancova_additive_model(object), ...)
}

#' @rdname residuals.pharma_ancova
#' @export
deviance.pharma_ancova <- function(object, ...) {
  stats::deviance(ancova_additive_model(object), ...)
}

#' @rdname residuals.pharma_ancova
#' @export
logLik.pharma_ancova <- function(object, REML = FALSE, ...) {
  stats::logLik(ancova_additive_model(object), REML = REML, ...)
}
