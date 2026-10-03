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
#' @details
#' Supply correctly aligned `(start, stop]` intervals and covariate values
#' for each subject. This wrapper delegates to `coxph()`; it does not check
#' whether intervals overlap or whether subject records are complete.
#' @export
#'
#' @examples
#' # Eight subjects contribute baseline and later intervals. The covariate
#' # changes for some subjects; events occur in both covariate groups.
#' interval_data <- data.frame(
#'   start = rep(c(0, 5), 8),
#'   stop = as.vector(rbind(rep(5, 8), 6:13)),
#'   status = rep(c(0, 1), 8),
#'   treatment = as.vector(rbind(
#'     c(0, 0, 1, 1, 0, 0, 1, 1),
#'     c(0, 1, 1, 0, 1, 0, 0, 1)
#'   ))
#' )
#' fit <- pharma_cox_timevarying(
#'   survival::Surv(start, stop, status) ~ treatment,
#'   data = interval_data
#' )
#' summary(fit)
pharma_cox_timevarying <- function(formula, data, ...) {
  survival::coxph(formula = formula, data = data, ...)
}
