#' Fit a Cox model with time-varying covariates
#'
#' Fit counting-process `Surv(start, stop, status)` intervals with
#' `survival::coxph()` for time-varying covariates. The helper checks the
#' selected intervals and model variables before fitting.
#'
#' @param formula A two-sided model formula with a counting-process
#'   `Surv(start, stop, status)` response.
#' @param data A nonempty data frame containing the model variables.
#' @param ... Additional arguments passed to `survival::coxph`.
#' @param subset Optional logical expression evaluated in `data`, or a
#'   nonmissing logical vector with one value per input row. Applied before
#'   the model variables are checked.
#'
#' @return A `coxph` object.
#' @details
#' Intervals must have finite start and stop times with start strictly less
#' than stop, and all selected model variables must be complete. Options in
#' `...` must not remove further rows. Supply aligned `(start, stop]` intervals
#' and covariate values for each subject; the helper does not check for
#' overlapping intervals, gaps, or complete subject histories. For an
#' ordinary right-censored response, use `pharma_survival_fit()` instead.
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
pharma_cox_timevarying <- function(formula, data, ..., subset = NULL) {
  if (!inherits(formula, "formula") || length(formula) != 3L) {
    stop("formula must be a two-sided counting-process survival formula",
         call. = FALSE)
  }
  if (!is.data.frame(data) || nrow(data) == 0L) {
    stop("data must be a nonempty data frame", call. = FALSE)
  }

  analysis_data <- data
  if (!missing(subset) && !is.null(substitute(subset))) {
    selected <- eval(substitute(subset), envir = data,
                     enclos = parent.frame())
    if (!is.logical(selected) || length(selected) != nrow(data) ||
        anyNA(selected)) {
      stop("subset must select rows with a complete logical vector",
           call. = FALSE)
    }
    analysis_data <- data[selected, , drop = FALSE]
  }
  if (nrow(analysis_data) == 0L) {
    stop("no observations remain after the subset", call. = FALSE)
  }

  # Check the selected model frame before coxph can drop incomplete rows.
  model_data <- stats::model.frame(
    formula, data = analysis_data, na.action = stats::na.pass
  )
  response <- stats::model.response(model_data)
  if (!inherits(response, "Surv") || ncol(response) != 3L ||
      !identical(attr(response, "type"), "counting")) {
    stop("formula must have a counting-process Surv(start, stop, status) response",
         call. = FALSE)
  }
  if (anyNA(response) || any(!is.finite(response[, 1:2])) ||
      any(response[, 1L] >= response[, 2L])) {
    stop("counting-process intervals need finite start < stop and complete status",
         call. = FALSE)
  }
  if (anyNA(model_data)) {
    stop("model variables must be complete in the selected rows",
         call. = FALSE)
  }

  # Forward the original expressions, not ..1/..2 promises from this frame.
  # coxph evaluates weights/id in its model frame and the formula environment.
  fit_call <- match.call(expand.dots = TRUE)
  fit_call[[1L]] <- quote(survival::coxph)
  fit_call$subset <- NULL  # Original-row selection has already been applied.
  # Embed the checked objects so neither data nor formula is evaluated twice.
  fit_call$data <- analysis_data
  fit_call$formula <- formula
  fit <- eval(fit_call, envir = parent.frame())
  if (fit$n != nrow(analysis_data)) {
    stop("coxph changed the selected analysis rows; check arguments in ...",
         call. = FALSE)
  }
  fit
}
