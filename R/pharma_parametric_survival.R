#' Fit a parametric survival model
#'
#' Convenience wrapper around `survival::survreg` for parametric time-to-event analyses.
#'
#' @param formula A model formula of the form `Surv(time, status) ~ predictors`.
#' @param data A data frame containing the variables used in the model.
#' @param dist Distribution to use. Defaults to "weibull".
#' @param ... Additional arguments passed to `survival::survreg`.
#'
#' @return A `survreg` object.
#' @export
#'
#' @examples
#' pharma_parametric_survival(Surv(time, status) ~ treatment,
#'   data = pharma_survival,
#'   dist = "weibull"
#' )
pharma_parametric_survival <- function(formula, data, dist = "weibull", ...) {
  survival::survreg(formula = formula, data = data, dist = dist, ...)
}
