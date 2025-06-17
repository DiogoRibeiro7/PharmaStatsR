#' Landmark analysis
#'
#' Performs a simple landmark analysis by including only individuals
#' who survive past the specified landmark time and refitting a Cox model.
#'
#' @param formula A survival formula `Surv(time, status) ~ predictors`.
#' @param data A data frame containing model variables including `time` and `status`.
#' @param landmark Numeric landmark time.
#' @param ... Additional arguments passed to `survival::coxph`.
#'
#' @return A `coxph` object fitted on landmarked data.
#' @export
#'
#' @examples
#' pharma_landmark_analysis(Surv(time, status) ~ treatment, data = df, landmark = 12)
pharma_landmark_analysis <- function(formula, data, landmark, ...) {
  mf <- model.frame(formula, data)
  y <- model.response(mf)
  keep <- y[, 1] >= landmark
  mf <- mf[keep, , drop = FALSE]
  y <- y[keep, , drop = FALSE]
  y[, 1] <- y[, 1] - landmark
  mf[[1]] <- survival::Surv(time = y[, 1], event = y[, 2])
  survival::coxph(formula, data = mf, ...)
}
