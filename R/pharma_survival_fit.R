#' Fit a Cox proportional hazards model
#'
#' Provides a thin wrapper around `survival::coxph` for time-to-event analyses.
#'
#' @param formula A model formula of the form `Surv(time, status) ~ predictors`.
#' @param data A data frame containing the variables used in the model.
#' @param ... Additional arguments passed to `survival::coxph`.
#'
#' @return A `coxph` object.
#' @export
#'
#' @examples
#' pharma_survival_fit(survival::Surv(time, status) ~ treatment, data = pharma_survival)
pharma_survival_fit <- function(formula, data, ...) {
  survival::coxph(formula = formula, data = data, ...)
}
