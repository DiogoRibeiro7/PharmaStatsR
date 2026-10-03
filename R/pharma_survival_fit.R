#' Fit a Cox proportional hazards model
#'
#' Delegates Cox proportional-hazards fitting to `survival::coxph()`.
#'
#' @param formula A survival model formula, typically
#'   `Surv(time, status) ~ predictors` for right-censored observations.
#' @param data A data frame containing the variables used in the model.
#' @param ... Additional arguments, including `subset`, `na.action`, and `ties`,
#'   passed to `survival::coxph()`.
#'
#' @return A `coxph` object. Coefficients for ordinary covariates are log
#'   hazard ratios under the fitted proportional-hazards model.
#' @details For a right-censored `Surv(time, status)` response, code censoring
#'   as 0 and the event as 1. `coxph()` handles row selection and missingness;
#'   inspect the fitted `n` and `na.action` before interpreting a result.
#'   Use `pharma_cox_timevarying()` for checked counting-process intervals.
#' @export
#'
#' @examples
#' pharma_survival_fit(survival::Surv(time, status) ~ treatment, data = pharma_survival)
pharma_survival_fit <- function(formula, data, ...) {
  # Preserve unevaluated subset/weights expressions for coxph's model frame.
  call <- match.call()
  call[[1L]] <- quote(survival::coxph)
  eval(call, parent.frame())
}
