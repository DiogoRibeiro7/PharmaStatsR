#' Competing-risks regression
#'
#' Convenience wrapper around `cmprsk::crr` for Fine-Gray competing-risks models.
#'
#' @param formula A formula of the form `Surv(time, status) ~ predictors` where
#'   `status` codes the event type.
#' @param data A data frame containing model variables.
#' @param failcode Integer code for the event of interest. Defaults to 1.
#' @param cencode Integer code for censoring. Defaults to 0.
#' @param ... Additional arguments passed to `cmprsk::crr`.
#'
#' @return A `crr` object.
#' @export
#'
#' @examples
#' pharma_competing_risks(Surv(time, status) ~ treatment, data = df)
pharma_competing_risks <- function(formula, data, failcode = 1, cencode = 0, ...) {
  mf <- model.frame(formula, data)
  y <- model.response(mf)
  time <- y[, 1]
  status <- y[, 2]
  covariates <- model.matrix(attr(mf, "terms"), mf)[, -1, drop = FALSE]
  cmprsk::crr(time, status, covariates, failcode = failcode, cencode = cencode, ...)
}
