#' Cochran-Armitage trend test for ordered binary rates
#'
#' Test for a linear trend in event proportions across ordered groups using
#' the Cochran-Armitage score statistic.
#'
#' @param x A numeric K-by-2 matrix or table of nonnegative whole-number counts.
#'   Rows define ordered groups or doses; column 1 is events and column 2
#'   non-events.
#' @param scores Optional strictly increasing finite numeric scores of length K.
#'   Defaults to `0:(K - 1)`.
#' @param alternative Character string: `"two.sided"`, `"greater"`, or
#'   `"less"`.
#'
#' @return An object of class `htest` with the signed Z statistic.
#' @details
#' The test uses the pooled event proportion under the null. Positive Z means
#' event rates tend to increase with the supplied scores. Score translation
#' and positive rescaling do not change Z. This is an asymptotic trend test,
#' not a dose-response model.
#' @export
#'
#' @examples
#' tab <- cbind(events = c(2, 5, 9, 14), nonevents = c(18, 15, 11, 6))
#' pharma_cochran_armitage_test(tab)
pharma_cochran_armitage_test <- function(
    x,
    scores = NULL,
    alternative = c("two.sided", "greater", "less")) {
  if (!(is.matrix(x) || inherits(x, "table")) ||
      length(dim(x)) != 2L || ncol(x) != 2L || nrow(x) < 2L) {
    stop("x must be a numeric K-by-2 matrix or table with K >= 2",
         call. = FALSE)
  }
  x <- as.matrix(x)
  if (!is.numeric(x) || anyNA(x) || !all(is.finite(x)) ||
      any(x < 0) || any(x != floor(x))) {
    stop("x must contain finite nonnegative whole-number counts",
         call. = FALSE)
  }
  totals <- rowSums(x)
  if (any(totals <= 0)) {
    stop("Every ordered group must have positive total count", call. = FALSE)
  }

  k <- nrow(x)
  if (is.null(scores)) {
    scores <- seq.int(0, k - 1L)
  }
  if (!is.numeric(scores) || length(scores) != k || anyNA(scores) ||
      !all(is.finite(scores))) {
    stop("scores must be finite numeric values with one score per group",
         call. = FALSE)
  }
  if (any(diff(scores) <= 0)) {
    stop("scores must be strictly increasing", call. = FALSE)
  }

  alternative <- match.arg(alternative)

  events <- x[, 1L]
  total_n <- sum(totals)
  total_events <- sum(events)
  if (total_events == 0 || total_events == total_n) {
    stop("Pooled event proportion must lie strictly between 0 and 1",
         call. = FALSE)
  }

  p <- total_events / total_n
  q <- 1 - p
  centered_events <- events - totals * p
  numerator <- sum(scores * centered_events)
  score_ss <- sum(totals * scores^2) -
    sum(totals * scores)^2 / total_n
  variance <- p * q * score_ss
  if (!is.finite(variance) || variance <= 0) {
    stop("Trend statistic is undefined for these counts and scores",
         call. = FALSE)
  }

  statistic <- numerator / sqrt(variance)
  p_value <- switch(
    alternative,
    two.sided = 2 * stats::pnorm(-abs(statistic)),
    greater = stats::pnorm(statistic, lower.tail = FALSE),
    less = stats::pnorm(statistic)
  )

  structure(
    list(
      statistic = c(Z = statistic),
      parameter = NULL,
      p.value = p_value,
      alternative = alternative,
      method = "Cochran-Armitage test for trend",
      data.name = deparse(substitute(x)),
      scores = scores,
      pooled.event.rate = p
    ),
    class = "htest"
  )
}
