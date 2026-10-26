#' Extract estimates and predict from an ANCOVA fit
#'
#' Use the standard R model interface with the saved additive linear model
#' from [pharma_ancova()]. These methods delegate to the corresponding `lm`
#' methods without refitting or changing the interaction diagnostic or stored
#' adjusted means.
#'
#' @param object A result returned by [pharma_ancova()], including an RDS
#'   round trip. Its saved additive `model` must remain an `lm` fit.
#' @param parm Coefficient names or positions for [stats::confint()]. Omit to
#'   obtain intervals for all coefficients.
#' @param level Confidence level for coefficient intervals; defaults to 0.95.
#' @param newdata Optional data frame of prediction rows. Omit to predict the
#'   observations retained in the additive model, in their stored order.
#'   Supply the original treatment and covariate columns for new observations.
#' @param ... Arguments forwarded to the corresponding native method.
#'   Prediction supports [stats::predict.lm()] options such as `se.fit`,
#'   `interval`, `level`, `type`, `terms`, `na.action`, `weights` and `pred.var`.
#'   Arguments, validation, warnings and output shapes follow the installed
#'   R version's native method.
#'
#' @return `coef()` returns the named additive coefficient vector; `vcov()`
#'   returns its model-based covariance matrix. `confint()` returns coefficient
#'   confidence limits as a matrix. `predict()` retains [stats::predict.lm()]
#'   return types: ordinarily a named prediction vector, a matrix for intervals
#'   or term contributions, or a list when `se.fit = TRUE`.
#' @details
#' These are additive-model results. Use the corresponding methods on
#' `object$interaction_model` to inspect that separate fit. Neither coefficient
#' intervals nor predictions alter `object$adjusted_means`. The fit's
#' `conf.level` applies to the stored adjusted means; new calls use their own
#' `level` (0.95 by default for both coefficient and prediction intervals).
#' Intervals are individual model-based intervals, without a multiplicity
#' adjustment or robust covariance correction.
#'
#' Confidence intervals for predictions describe the model mean. Prediction
#' intervals add future-observation error variance under the fitted error
#' model. For weighted fits, weights express relative precision, not frequency
#' or survey-design weights. Specify appropriate new-observation `weights` or
#' `pred.var` for prediction intervals; native warnings and defaults are retained.
#' Omitting `newdata` uses only the selected analysis rows, not excluded rows
#' from the original input. Missing new predictors, unknown treatment levels,
#' and term output follow [stats::predict.lm()].
#'
#' Existing saved ANCOVA results work after loading PharmaStatsR. The saved
#' model frame and coefficients are used; the original training data object
#' need not still exist. No models are refitted and no random numbers are drawn.
#' @examples
#' trial <- data.frame(
#'   response = c(11, 11, 13, 17, 14, 16, 20, 26),
#'   treatment = factor(rep(c("A", "B"), each = 4)),
#'   baseline = rep(0:3, 2)
#' )
#' fit <- pharma_ancova(response ~ treatment + baseline, trial)
#' coef(fit)
#' vcov(fit)
#' confint(fit, parm = "treatmentB", level = 0.9)
#' future <- data.frame(treatment = c("A", "B"), baseline = c(1, 2))
#' predict(fit, future)
#' predict(fit, future, interval = "confidence", level = 0.9)
#' predict(fit, future, se.fit = TRUE)
#' @seealso [summary.pharma_ancova()], [residuals.pharma_ancova()],
#'   [stats::predict.lm()], [stats::confint()]
#' @export
coef.pharma_ancova <- function(object, ...) {
  stats::coef(ancova_additive_model(object), ...)
}

#' @rdname coef.pharma_ancova
#' @export
vcov.pharma_ancova <- function(object, ...) {
  stats::vcov(ancova_additive_model(object), ...)
}

#' @rdname coef.pharma_ancova
#' @export
confint.pharma_ancova <- function(object, parm, level = 0.95, ...) {
  model <- ancova_additive_model(object)
  if (missing(parm)) {
    return(stats::confint(model, level = level, ...))
  }
  stats::confint(model, parm = parm, level = level, ...)
}

#' @rdname coef.pharma_ancova
#' @export
predict.pharma_ancova <- function(object, newdata, ...) {
  model <- ancova_additive_model(object)
  if (missing(newdata)) {
    return(stats::predict(model, ...))
  }
  stats::predict(model, newdata = newdata, ...)
}

ancova_additive_model <- function(object) {
  model <- if (is.list(object)) object[["model", exact = TRUE]] else NULL
  if (!identical(class(model), "lm")) {
    stop("The saved additive model must be an lm fit from pharma_ancova()", call. = FALSE)
  }
  model
}
