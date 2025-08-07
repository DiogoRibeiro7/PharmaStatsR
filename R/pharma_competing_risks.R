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
#' if (requireNamespace("cmprsk", quietly = TRUE)) {
#'   df <- data.frame(
#'     time = c(5, 6, 7),
#'     status = c(1, 2, 0),
#'     treatment = c(0, 1, 1)
#'   )
#'   pharma_competing_risks(survival::Surv(time, status) ~ treatment, df)
#' }
pharma_competing_risks <- function(formula, data, failcode = 1, cencode = 0, ...) {
  validate_inputs(data, formula)
  if (!requireNamespace("cmprsk", quietly = TRUE)) {
    stop(
      "Package 'cmprsk' is required for this function.\n",
      "Please install it with: install.packages('cmprsk')"
    )
  }
  mf <- stats::model.frame(formula, data)
  y <- stats::model.response(mf)
  time <- y[, 1]
  status <- y[, 2]
  covariates <- stats::model.matrix(attr(mf, "terms"), mf)[, -1, drop = FALSE]
  cmprsk::crr(time, status, covariates, failcode = failcode, cencode = cencode, ...)
}
