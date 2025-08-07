#' Two One-Sided Tests (TOST) for Equivalence
#'
#' Perform a two one-sided t-test (TOST) to assess equivalence of two means within specified bounds.
#'
#' @param x Numeric vector of observations from group 1.
#' @param y Numeric vector of observations from group 2.
#' @param formula A model formula specifying the response and grouping variable.
#' @param data A data frame containing the variables in the formula.
#' @param low_eqbound Lower equivalence bound for the difference (group1 - group2).
#' @param high_eqbound Upper equivalence bound for the difference.
#' @param alpha Significance level for the one-sided tests.
#' @param ... Additional arguments (ignored).
#'
#' @return A list containing the TOST t statistics and p-value along with the estimated difference and confidence interval.
#' @export
#'
#' @examples
#' # Vector interface
#' pharma_tost(rnorm(30, 0, 1), rnorm(30, 0.1, 1), -0.5, 0.5)
#'
#' # Formula interface
#' pharma_tost(response ~ treatment, data = pharma_sample, -0.5, 0.5)
pharma_tost <- function(x, ...) {
  UseMethod("pharma_tost")
}

#' @rdname pharma_tost
#' @export
pharma_tost.default <- function(x, y, low_eqbound, high_eqbound, alpha = 0.05, ...) {
  pharma_log("INFO", "Running pharma_tost.default")
  check_numeric_vector(x, "x")
  check_numeric_vector(y, "y")
  if (length(x) < 2 || length(y) < 2) {
    stop(
      "`x` and `y` must have at least two observations; got lengths ",
      length(x), " and ", length(y)
    )
  }
  check_numeric_scalar(low_eqbound, "low_eqbound")
  check_numeric_scalar(high_eqbound, "high_eqbound")
  if (low_eqbound >= high_eqbound) {
    stop(
      "`low_eqbound` (", low_eqbound, ") must be less than `high_eqbound` (",
      high_eqbound, ")"
    )
  }
  check_numeric_scalar(alpha, "alpha", lower = 0, upper = 1)
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

#' @rdname pharma_tost
#' @export
pharma_tost.formula <- function(formula, data, low_eqbound, high_eqbound, alpha = 0.05, ...) {
  pharma_log("INFO", "Running pharma_tost.formula")
  validate_inputs(data, formula)
  mf <- stats::model.frame(formula, data)
  if (ncol(mf) != 2) {
    stop(
      "`formula` must specify one response and one grouping variable; got ",
      ncol(mf), " terms"
    )
  }
  if (anyNA(mf)) {
    stop("Variables in `data` used by `formula` contain NA values; remove or impute them before calling `pharma_tost`")
  }
  response <- mf[[1]]
  if (!is.numeric(response)) {
    stop("Response variable must be numeric")
  }
  if (!all(is.finite(response))) {
    stop("Response variable must contain only finite values")
  }
  group <- mf[[2]]
  group <- as.factor(group)
  if (nlevels(group) != 2) {
    stop("Grouping variable must have exactly two levels; found ", nlevels(group))
  }
  split_resp <- split(response, group)
  pharma_tost.default(split_resp[[1]], split_resp[[2]], low_eqbound, high_eqbound, alpha, ...)
}
