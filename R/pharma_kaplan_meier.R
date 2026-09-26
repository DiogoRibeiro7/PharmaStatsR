#' Kaplan-Meier curve with log-rank test
#'
#' Fits a Kaplan-Meier survival curve and optionally performs a log-rank test.
#' Requires the `survival` package.
#'
#' @param formula A survival formula of the form `Surv(time, status) ~ group`.
#' @param data A data frame containing the variables used in the model.
#' @param log_rank Logical; perform a log-rank test? Default is TRUE.
#' @param ... Additional arguments passed to `survival::survfit`.
#'
#' @return If `log_rank = TRUE`, a list with components `fit` (the survfit
#'   object) and `test` (the survdiff object). Otherwise the survfit object.
#' @export
#'
#' @examples
#' pharma_kaplan_meier(survival::Surv(time, status) ~ treatment, data = pharma_survival)
pharma_kaplan_meier <- function(formula, data, log_rank = TRUE, ...) {
  validate_inputs(data, formula)
  if (!requireNamespace("survival", quietly = TRUE)) {
    stop(
      "Package 'survival' is required for pharma_kaplan_meier(); ",
      "install it with install.packages('survival')"
    )
  }
  fit <- survival::survfit(formula, data = data, ...)
  if (isTRUE(log_rank)) {
    test <- survival::survdiff(formula, data = data, ...)
    return(list(fit = fit, test = test))
  }
  fit
}
