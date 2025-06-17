#' Rate and Risk Difference and Ratio Metrics
#'
#' Calculate risk difference and risk ratio between two groups with Wald confidence intervals.
#'
#' @param event1 Number of events in group 1.
#' @param n1 Total observations in group 1.
#' @param event2 Number of events in group 2.
#' @param n2 Total observations in group 2.
#' @param conf.level Confidence level for the intervals.
#'
#' @return A list with estimates and confidence intervals for the risk difference and risk ratio.
#' @export
#'
#' @examples
#' pharma_rate_metrics(10, 100, 15, 110)
pharma_rate_metrics <- function(event1, n1, event2, n2, conf.level = 0.95) {
  if (any(c(event1, event2) < 0) || any(c(n1, n2) <= 0)) {
    stop("Event counts must be non-negative and sample sizes positive")
  }
  if (event1 > n1 || event2 > n2) {
    stop("Event counts cannot exceed sample sizes")
  }
  p1 <- event1 / n1
  p2 <- event2 / n2
  rd <- p1 - p2
  rr <- if (p2 == 0) Inf else p1 / p2
  z <- stats::qnorm(1 - (1 - conf.level) / 2)
  se_rd <- sqrt(p1 * (1 - p1) / n1 + p2 * (1 - p2) / n2)
  rd_ci <- rd + c(-1, 1) * z * se_rd
  if (event1 == 0 || event2 == 0) {
    rr_ci <- c(NA_real_, NA_real_)
  } else {
    se_log_rr <- sqrt((1 - p1) / (event1) + (1 - p2) / (event2))
    rr_ci <- exp(log(rr) + c(-1, 1) * z * se_log_rr)
  }
  list(risk_difference = rd, rd_ci = rd_ci,
       risk_ratio = rr, rr_ci = rr_ci)
}
