#' Fit a joint longitudinal-survival model
#'
#' Provides a wrapper around `JM::jointModel` for fitting joint models
#' that link a linear mixed-effects model with a Cox proportional hazards model.
#' Requires the optional **JM** package.
#'
#' @param lmeFit An `nlme::lme` mixed-effects model. `lme4::lmer` fits are not
#'   supported by `JM::jointModel`.
#' @param coxFit A `survival::coxph` fit created with `x = TRUE`.
#' @param timeVar Character string indicating the name of the time variable in
#'   the longitudinal model.
#' @param ... Additional arguments passed to `JM::jointModel`.
#'
#' @details
#' The longitudinal and survival fits must use the same subjects in the same
#' order, and the time scales must agree. The wrapper does not verify this
#' alignment; check it before fitting. See `JM::jointModel` for further model
#' structure and estimation requirements.
#'
#' @return An object of class `jointModel`.
#' @export
#'
#' @examples
#' # Fit compatible longitudinal and survival models on matched data first.
pharma_joint_model <- function(lmeFit, coxFit, timeVar, ...) {
  if (!.pharma_jm_available()) {
    stop(
      "Optional package 'JM' is required for pharma_joint_model(). Install it with install.packages('JM').",
      call. = FALSE
    )
  }
  if (!inherits(lmeFit, "lme")) {
    stop("lmeFit must be an nlme::lme object", call. = FALSE)
  }
  if (!inherits(coxFit, "coxph")) {
    stop("coxFit must be a survival::coxph object", call. = FALSE)
  }
  if (!is.matrix(coxFit$x)) {
    stop("coxFit must be fitted with x = TRUE", call. = FALSE)
  }
  if (!is.character(timeVar) || length(timeVar) != 1L ||
      is.na(timeVar) || !nzchar(timeVar)) {
    stop("timeVar must be a nonempty character string", call. = FALSE)
  }

  # Verify that the time variable is present in the longitudinal data
  lme_data <- tryCatch(lmeFit$data, error = function(e) NULL)
  if (!is.null(lme_data) && !timeVar %in% names(lme_data)) {
    stop("timeVar not found in the longitudinal model's data", call. = FALSE)
  }

  # All checks passed; delegate to JM::jointModel for the heavy lifting
  JM::jointModel(lmeFit, coxFit, timeVar = timeVar, ...)
}

.pharma_jm_available <- function() {
  requireNamespace("JM", quietly = TRUE)
}
