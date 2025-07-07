#' Two One-Sided Tests (TOST) for Equivalence
#'
#' Perform a two one-sided t-test (TOST) to assess equivalence of two means within specified bounds.
#'
#' @param x Numeric vector of observations from group 1.
#' @param y Numeric vector of observations from group 2.
#' @param low_eqbound Lower equivalence bound for the difference (group1 - group2).
#' @param high_eqbound Upper equivalence bound for the difference.
#' @param alpha Significance level for the one-sided tests.
#'
#' @return A list containing the TOST t statistics and p-value along with the estimated difference and confidence interval.
#' @export
#'
#' @examples
#' pharma_tost(rnorm(30, 0, 1), rnorm(30, 0.1, 1), -0.5, 0.5)
pharma_tost <- function(x, y, low_eqbound, high_eqbound, alpha = 0.05) {
  if (!is.numeric(x) || !is.numeric(y)) {
    stop("`x` and `y` must be numeric vectors")
  }
  if (length(x) < 2 || length(y) < 2) {
    stop("`x` and `y` must have at least two observations")
  }
  if (low_eqbound >= high_eqbound) {
    stop("`low_eqbound` must be less than `high_eqbound`")
  }
  n1 <- length(x)
  n2 <- length(y)
  diff <- mean(x) - mean(y)
  se <- sqrt(stats::var(x) / n1 + stats::var(y) / n2)
  df <- n1 + n2 - 2
  t1 <- (diff - low_eqbound) / se
  t2 <- (diff - high_eqbound) / se
  p1 <- stats::pt(t1, df = df, lower.tail = FALSE)
  p2 <- stats::pt(-t2, df = df, lower.tail = FALSE)
  p_value <- max(p1, p2)
  crit <- stats::qt(1 - alpha, df = df)
  ci <- diff + c(-1, 1) * crit * se
  list(
    statistic = c(t1 = t1, t2 = t2), p.value = p_value,
    diff = diff, conf.int = ci, df = df
  )
}
