#' Fit a joint longitudinal-survival model
#'
#' Provides a wrapper around `JM::jointModel` for fitting joint models
#' that link a linear mixed-effects model with a Cox proportional hazards model.
#'
#' @param lmeFit A mixed-effects model object of class `lme`.
#' @param coxFit A Cox proportional hazards model object of class `coxph`.
#' @param timeVar Character string indicating the name of the time variable in
#'   the longitudinal model.
#' @param ... Additional arguments passed to `JM::jointModel`.
#'
#' @return An object of class `jointModel`.
#' @export
#'
#' @examples
#' if (requireNamespace("JM", quietly = TRUE) &&
#'   requireNamespace("nlme", quietly = TRUE)) {
#'   lme_fit <- nlme::lme(response ~ time,
#'     random = ~ time | subject,
#'     data = pharma_sample
#'   )
#'   cox_fit <- survival::coxph(survival::Surv(futime, status) ~ treatment,
#'     data = pharma_survival
#'   )
#'   pharma_joint_model(lme_fit, cox_fit, timeVar = "time")
#' }
pharma_joint_model <- function(lmeFit, coxFit, timeVar, ...) {
  # Ensure the JM package is available before proceeding
  if (!requireNamespace("JM", quietly = TRUE)) {
    stop("Package 'JM' is required for pharma_joint_model()")
  }
  if (!inherits(lmeFit, c("lme", "lmerMod"))) {
    stop("lmeFit must be a mixed-effects model of class 'lme' or 'lmerMod'")
  }
  if (!inherits(coxFit, "coxph")) {
    stop("coxFit must be a 'coxph' object")
  }
  if (!is.character(timeVar) || length(timeVar) != 1) {
    stop("timeVar must be a single character string")
  }

  # Verify that the time variable is present in the longitudinal data
  lme_data <- tryCatch(lmeFit$data, error = function(e) NULL)
  if (!is.null(lme_data) && !timeVar %in% names(lme_data)) {
    stop("timeVar not found in the longitudinal model's data")
  }

  # All checks passed; delegate to JM::jointModel for the heavy lifting
  JM::jointModel(lmeFit, coxFit, timeVar = timeVar, ...)
}
