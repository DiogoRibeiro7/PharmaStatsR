#' Landmark analysis
#'
#' Fits a Cox model among individuals still observed after the landmark,
#' measuring survival time from the landmark. Supports right-censored
#' `Surv(time, status)` responses. The risk set is selected from complete
#' response times and statuses before predictor values are checked.
#'
#' @param formula A right-censored survival formula.
#' @param data A data frame containing the variables in `formula`.
#' @param landmark A finite, nonnegative landmark time.
#' @param ... Additional arguments passed to `survival::coxph`.
#' @param subset Optional logical expression evaluated in `data`, or a
#'   nonmissing logical vector with one value per row. Selection precedes
#'   the landmark restriction and covariate evaluation.
#'
#' @return A `coxph` object fitted on the selected landmark risk set.
#' @details Only subjects whose recorded follow-up extends strictly beyond
#'   the landmark are included. Their times are shifted to start at zero;
#'   event indicators are unchanged. Covariates must be complete in this
#'   risk set. This is an ordinary Cox model conditional on surviving and
#'   remaining observed to the landmark; it does not account for earlier
#'   outcomes or establish that censoring is independent.
#' @export
#'
#' @examples
#' pharma_landmark_analysis(
#'   survival::Surv(time, status) ~ treatment,
#'   data = pharma_survival, landmark = 5
#' )
pharma_landmark_analysis <- function(formula, data, landmark, ...,
                                     subset = NULL) {
  if (!inherits(formula, "formula") || length(formula) != 3L) {
    stop("formula must be a two-sided right-censored survival formula")
  }
  if (!is.data.frame(data)) {
    stop("data must be a data frame")
  }
  if (!is.numeric(landmark) || length(landmark) != 1L ||
      is.na(landmark) || !is.finite(landmark) || landmark < 0) {
    stop("landmark must be a finite, nonnegative number")
  }

  analysis_data <- data
  if (!missing(subset) && !is.null(substitute(subset))) {
    selected <- eval(substitute(subset), envir = data,
                     enclos = parent.frame())
    if (!is.logical(selected) || length(selected) != nrow(data) ||
        anyNA(selected)) {
      stop("subset must select rows with a complete logical vector")
    }
    analysis_data <- data[selected, , drop = FALSE]
  }
  if (nrow(analysis_data) == 0L) {
    stop("no observations remain after the subset")
  }

  # Evaluate the response first: missing covariates in subjects outside the
  # landmark risk set must not prevent an otherwise complete analysis.
  response_formula <- formula
  response_formula[[3L]] <- 1
  response_data <- stats::model.frame(
    response_formula, data = analysis_data, na.action = stats::na.fail
  )
  response <- stats::model.response(response_data)
  if (!inherits(response, "Surv") || ncol(response) != 2L ||
      !identical(attr(response, "type"), "right")) {
    stop("formula must have a right-censored Surv(time, status) response")
  }

  # Only subjects observed beyond the landmark enter the risk set.
  keep <- response[, 1L] > landmark
  if (!any(keep)) {
    stop("no observations remain after the landmark")
  }
  landmark_data <- analysis_data[keep, , drop = FALSE]
  response_name <- ".pharma_landmark_response"
  while (response_name %in% c(names(landmark_data), all.vars(formula))) {
    response_name <- paste0(response_name, "_")
  }
  landmark_data[[response_name]] <- survival::Surv(
    response[keep, 1L] - landmark, response[keep, 2L]
  )
  landmark_formula <- formula
  landmark_formula[[2L]] <- as.name(response_name)
  stats::model.frame(landmark_formula, data = landmark_data,
                     na.action = stats::na.fail)
  survival::coxph(landmark_formula, data = landmark_data, ...)
}
