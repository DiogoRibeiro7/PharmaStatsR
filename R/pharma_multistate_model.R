#' Estimate cumulative transition hazards from a multistate Cox model
#'
#' Pass a prepared Cox fit and transition matrix to `mstate::msfit()`.
#' The result contains cumulative transition hazards, not state probabilities.
#'
#' @param coxFit A `survival::coxph()` model fitted on data prepared with
#'   `mstate::msprep()`, usually with `strata(trans)` and `method = "breslow"`.
#' @param trans A transition matrix created by `mstate::transMat()` or a
#'   corresponding helper such as `mstate::trans.illdeath()`.
#' @param ... Arguments passed to `mstate::msfit()`. Supply `newdata` with one
#'   row per transition and a numeric `strata` column when the Cox model has
#'   covariates. `newdata` may be omitted only for a model with right-hand side
#'   `~ strata(trans)`.
#'
#' @return An `msfit` object containing cumulative transition hazards.
#' @export
#'
#' @examples
#' # Prepare transition data with mstate::msprep(), fit a stratified Cox model,
#' # then pass its transition matrix and any required newdata to this helper.
pharma_multistate_model <- function(coxFit, trans, ...) {
  if (!inherits(coxFit, "coxph")) {
    stop("coxFit must be a 'coxph' object", call. = FALSE)
  }
  if (!.pharma_mstate_available()) {
    stop(
      "Optional package 'mstate' is required; install it with install.packages('mstate').",
      call. = FALSE
    )
  }
  if (!is.matrix(trans) || ncol(trans) != nrow(trans)) {
    stop(
      "trans must be a square transition matrix created by mstate::transMat()",
      call. = FALSE
    )
  }

  mstate::msfit(coxFit, trans = trans, ...)
}

.pharma_mstate_available <- function() {
  requireNamespace("mstate", quietly = TRUE)
}
