#' Fit a Cox model with time-varying covariates
#'
#' Wrapper around `survival::coxph` supporting counting-process style
#' `Surv(start, stop, status)` input to model time-varying covariates.
#'
#' @param formula A model formula using a `Surv(start, stop, status)` response.
#' @param data A data frame containing the variables used in the model.
#' @param ... Additional arguments passed to `survival::coxph`.
#'
#' @return A `coxph` object.
#' @export
#'
#' @examples
#' pharma_cox_timevarying(Surv(start, stop, status) ~ x + strata(id), data = df)
pharma_cox_timevarying <- function(formula, data, ...) {
  survival::coxph(formula = formula, data = data, ...)
}
