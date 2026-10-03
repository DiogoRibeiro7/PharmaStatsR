#' Fit a parametric survival model
#'
#' Delegates parametric time-to-event regression to `survival::survreg()`.
#'
#' @param formula A survival model formula, typically
#'   `Surv(time, status) ~ predictors` for right-censored observations.
#' @param data A data frame containing the variables used in the model.
#' @param dist Distribution accepted by `survival::survreg()`; defaults to
#'   `"weibull"`.
#' @param ... Additional arguments, including `subset` and `na.action`,
#'   passed to `survival::survreg()`.
#'
#' @return A `survreg` object. With the default Weibull model, covariate
#'   coefficients describe log survival-time ratios, not Cox log hazard ratios.
#' @details For a right-censored `Surv(time, status)` response, code censoring
#'   as 0 and the event as 1. `survreg()` handles row selection and missingness;
#'   inspect the fitted `n` and `na.action`. For Weibull fits, the fitted
#'   `scale` is the reciprocal of the usual Weibull shape parameter.
#' @export
#'
#' @examples
#' pharma_parametric_survival(survival::Surv(time, status) ~ treatment,
#'   data = pharma_survival,
#'   dist = "weibull"
#' )
pharma_parametric_survival <- function(formula, data, dist = "weibull", ...) {
  # Preserve unevaluated subset/weights expressions for survreg's model frame.
  call <- match.call()
  call[[1L]] <- quote(survival::survreg)
  eval(call, parent.frame())
}
