#' Landmark analysis
#'
#' Fits a Cox model among individuals still observed after the landmark,
#' measuring survival time from the landmark. Supports right-censored
#' `Surv(time, status)` responses.
#'
#' @param formula A right-censored survival formula.
#' @param data A data frame containing the variables in `formula`.
#' @param landmark A finite, nonnegative landmark time.
#' @param ... Additional arguments passed to `survival::coxph`.
#'
#' @return A `coxph` object fitted on landmarked data.
#' @export
#'
#' @examples
#' pharma_landmark_analysis(
#'   survival::Surv(time, status) ~ treatment,
#'   data = pharma_survival, landmark = 5
#' )
pharma_landmark_analysis <- function(formula, data, landmark, ...) {
  if (!is.data.frame(data)) {
    stop("data must be a data frame")
  }
  if (!is.numeric(landmark) || length(landmark) != 1L ||
      is.na(landmark) || !is.finite(landmark) || landmark < 0) {
    stop("landmark must be a finite, nonnegative number")
  }

  model_data <- stats::model.frame(formula, data = data,
                                   na.action = stats::na.fail)
  response <- stats::model.response(model_data)
  if (!inherits(response, "Surv") || ncol(response) != 2L ||
      attr(response, "type") != "right") {
    stop("formula must have a right-censored Surv(time, status) response")
  }

  # Only subjects observed beyond the landmark enter the risk set.
  keep <- response[, 1L] > landmark
  if (!any(keep)) {
    stop("no observations remain after the landmark")
  }
  landmark_data <- data[keep, , drop = FALSE]
  landmark_data$.pharma_landmark_response <- survival::Surv(
    response[keep, 1L] - landmark, response[keep, 2L]
  )
  landmark_formula <- formula
  landmark_formula[[2L]] <- as.name(".pharma_landmark_response")
  survival::coxph(landmark_formula, data = landmark_data, ...)
}
