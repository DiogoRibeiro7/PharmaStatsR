#' Kaplan–Meier curves with an optional log-rank comparison
#'
#' Fit a right-censored, single-event Kaplan–Meier curve and optionally
#' compare groups with an unweighted, ordinary log-rank test.
#'
#' @param formula A right-censored `Surv(time, status) ~ group` formula.
#'   Use `~ 1` for a single curve with `log_rank = FALSE`.
#' @param data A data frame with the response and group variables.
#' @param log_rank One nonmissing logical value. If `TRUE`, return a
#'   standard log-rank comparison along with the curves.
#' @param ... Named curve-only options passed to [survival::survfit()],
#'   such as `conf.type` or `conf.int`. With `log_rank = TRUE`, options
#'   changing the observations or estimator, such as `weights`, are rejected.
#' @param subset Optional logical expression evaluated within `data`, or
#'   logical vector with one nonmissing element per input row. It is applied
#'   before both the curve and the test.
#' @param na.action Missing-value handling function shared by the curve
#'   and test; defaults to [stats::na.omit()].
#' @param timefix One nonmissing logical value passed to both survival
#'   functions to control correction of near-tied event times.
#'
#' @return If `log_rank = TRUE`, a list with `fit` (a `survfit` object)
#'   and `test` (a `survdiff` object); otherwise the `survfit` object.
#' @details
#' A multi-state or counting-process response is outside this helper's
#' scope. The log-rank test uses `rho = 0`, has no weights, and does not
#' adjust for confounding, clustering, or repeated observations.
#' @export
#'
#' @examples
#' pharma_kaplan_meier(
#'   survival::Surv(time, status) ~ treatment, data = pharma_survival,
#'   conf.type = "log-log"
#' )
pharma_kaplan_meier <- function(formula, data, log_rank = TRUE, ...,
                                subset = NULL, na.action = stats::na.omit,
                                timefix = TRUE) {
  validate_inputs(data, formula)
  if (!requireNamespace("survival", quietly = TRUE)) {
    stop("Package 'survival' is required for pharma_kaplan_meier()",
         call. = FALSE)
  }
  if (!is.logical(log_rank) || length(log_rank) != 1L ||
      is.na(log_rank)) {
    stop("log_rank must be one nonmissing logical value", call. = FALSE)
  }
  if (!is.function(na.action)) {
    stop("na.action must be a function", call. = FALSE)
  }
  if (!is.logical(timefix) || length(timefix) != 1L ||
      is.na(timefix)) {
    stop("timefix must be one nonmissing logical value", call. = FALSE)
  }

  dots <- match.call(expand.dots = FALSE)$...
  if (length(dots) > 0L) {
    dot_names <- names(dots)
    if (is.null(dot_names) || any(!nzchar(dot_names))) {
      stop("all curve options in ... must be named", call. = FALSE)
    }
    # These options would change the estimator away from Kaplan–Meier.
    if (any(dot_names %in% c("stype", "ctype", "type", "istate", "etype"))) {
      stop("use survival::survfit() for alternative estimators",
           call. = FALSE)
    }
    if (log_rank &&
        any(dot_names %in% c("weights", "id", "cluster", "start.time"))) {
      stop("curve-only weights, clustering, or start.time cannot be paired ",
           "with the unweighted log-rank test", call. = FALSE)
    }
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
  model_data <- stats::model.frame(
    formula, data = analysis_data, na.action = na.action
  )
  response <- stats::model.response(model_data)
  if (!inherits(response, "Surv") ||
      !identical(attr(response, "type"), "right")) {
    stop("formula must have a right-censored single-event Surv response",
         call. = FALSE)
  }

  fit <- survival::survfit(
    formula, data = analysis_data, na.action = na.action,
    timefix = timefix, ...
  )
  if (!log_rank) {
    return(fit)
  }
  # survdiff evaluates timefix in the formula environment; insert its value
  # into the call so it is not looked up as a wrapper-local name in data.
  test_call <- substitute(
    survival::survdiff(
      formula, data = analysis_data, na.action = na.action,
      timefix = .TIMEFIX
    ),
    list(.TIMEFIX = timefix)
  )
  test <- eval(test_call)
  list(fit = fit, test = test)
}
