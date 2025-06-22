#' Fit a multistate illness-death model
#'
#' Wrapper around `mstate::msfit` for estimating transition-specific
#' hazards in multistate analyses.
#'
#' @param coxFit A Cox model fitted on data prepared with `mstate::msprep`.
#' @param trans A transition matrix created by `mstate::transMat`.
#' @param ... Additional arguments passed to `mstate::msfit`.
#'
#' @return An object of class `msfit`.
#' @export
#'
#' @examples
#' if (requireNamespace("mstate", quietly = TRUE)) {
#'   tmat <- mstate::transMat(list(c(2, 3), c(3), c()),
#'                            names = c("Healthy", "Ill", "Dead"))
#'   cfit <- survival::coxph(Surv(Tstart, Tstop, status) ~ treatment + strata(trans),
#'                           data = mstate_example, method = "breslow")
#'   pharma_multistate_model(cfit, tmat)
#' }
pharma_multistate_model <- function(coxFit, trans, ...) {
  if (!inherits(coxFit, "coxph")) {
    stop("coxFit must be a 'coxph' object")
  }
  if (!requireNamespace("mstate", quietly = TRUE)) {
    stop("Package 'mstate' is required for pharma_multistate_model()")
  }
  mstate::msfit(coxFit, trans = trans, ...)
}
