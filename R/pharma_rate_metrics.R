#' Risk difference and risk ratio for two groups
#'
#' Compare two independent binomial event counts. The risk difference uses a
#' Newcombe interval combining Wilson score intervals without continuity
#' correction. The risk ratio uses a log-scale interval after adding 0.5 to
#' each cell of the two-by-two table.
#'
#' @param event1 Number of events in group 1; a non-negative whole number.
#' @param n1 Total observations in group 1; a positive whole number.
#' @param event2 Number of events in group 2; a non-negative whole number.
#' @param n2 Total observations in group 2; a positive whole number.
#' @param conf.level Confidence level strictly between 0 and 1.
#'
#' @return A list with the unadjusted \code{risk_difference} (group 1 minus group 2),
#'   its two-sided \code{rd_ci}, the unadjusted \code{risk_ratio} (group 1 divided by
#'   group 2), and its two-sided \code{rr_ci}. The risk ratio is \code{NA_real_} if
#'   neither group has events, \code{Inf} if only group 1 has events, and zero if
#'   only group 2 has events. The adjusted ratio interval is finite for these
#'   zero-event cases and is not centered on the unadjusted point estimate.
#' @references
#' Newcombe RG (1998). Interval estimation for the difference between
#' independent proportions: comparison of eleven methods. Statistics in
#' Medicine 17:873-890. \url{https://pubmed.ncbi.nlm.nih.gov/9595617/}
#' @export
#'
#' @examples
#' pharma_rate_metrics(10, 100, 15, 110)
#' pharma_rate_metrics(0, 12, 0, 15)
pharma_rate_metrics <- function(event1, n1, event2, n2, conf.level = 0.95) {
  valid_count <- function(x, positive = FALSE) {
    is.numeric(x) && length(x) == 1L && is.finite(x) &&
      x >= as.integer(positive) && x %% 1 == 0
  }
  if (!valid_count(n1, positive = TRUE) ||
      !valid_count(n2, positive = TRUE)) {
    stop("`n1` and `n2` must be positive whole numbers", call. = FALSE)
  }
  if (!valid_count(event1) || !valid_count(event2)) {
    stop("`event1` and `event2` must be non-negative whole numbers",
         call. = FALSE)
  }
  if (event1 > n1 || event2 > n2) {
    stop("Event counts cannot exceed sample sizes", call. = FALSE)
  }
  if (!is.numeric(conf.level) || length(conf.level) != 1L ||
      !is.finite(conf.level) || conf.level <= 0 || conf.level >= 1) {
    stop("`conf.level` must be strictly between 0 and 1", call. = FALSE)
  }

  p1 <- event1 / n1
  p2 <- event2 / n2
  rd <- p1 - p2
  rr <- if (p2 == 0) {
    if (p1 == 0) NA_real_ else Inf
  } else {
    p1 / p2
  }
  z <- stats::qnorm((1 - conf.level) / 2, lower.tail = FALSE)

  wilson <- function(p, n) {
    z2 <- z^2
    center <- (p + z2 / (2 * n)) / (1 + z2 / n)
    half_width <- z * sqrt(p * (1 - p) / n + z2 / (4 * n^2)) /
      (1 + z2 / n)
    c(center - half_width, center + half_width)
  }
  ci1 <- wilson(p1, n1)
  ci2 <- wilson(p2, n2)
  rd_ci <- c(
    rd - sqrt((p1 - ci1[1])^2 + (ci2[2] - p2)^2),
    rd + sqrt((ci1[2] - p1)^2 + (p2 - ci2[1])^2)
  )

  # Half an event and half a non-event per group keep the log interval defined.
  adjusted1 <- (event1 + 0.5) / (n1 + 1)
  adjusted2 <- (event2 + 0.5) / (n2 + 1)
  se_log_rr <- sqrt(
    1 / (event1 + 0.5) - 1 / (n1 + 1) +
      1 / (event2 + 0.5) - 1 / (n2 + 1)
  )
  rr_ci <- exp(log(adjusted1 / adjusted2) + c(-1, 1) * z * se_log_rr)

  list(
    risk_difference = rd, rd_ci = rd_ci,
    risk_ratio = rr, rr_ci = rr_ci
  )
}
