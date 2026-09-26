#' Test equivalence of two independent means with Welch TOST
#'
#' Tests whether the difference between two population means lies strictly
#' between the supplied equivalence bounds. Both one-sided tests use Welch's
#' variance estimate and degrees of freedom, so equal variances are not assumed.
#'
#' @details
#' The estimated difference is the first group mean minus the second group
#' mean. The returned confidence interval has level 1 - 2 * alpha; equivalence
#' at level alpha holds when both one-sided tests reject their null hypotheses.
#' For the formula method, the first observed factor level is the first group.
#'
#' @param x Numeric vector of observations in the first group, or a two-sided
#'   formula for the formula method.
#' @param y Numeric vector of observations in the second group.
#' @param formula Two-sided formula specifying a numeric response and a group.
#' @param data Data frame containing the variables in formula.
#' @param low_eqbound Finite lower bound for the mean difference.
#' @param high_eqbound Finite upper bound for the mean difference.
#' @param alpha Numeric significance level strictly between 0 and 0.5.
#' @param ... Additional arguments; currently ignored.
#'
#' @return A list containing the two t statistics, the larger one-sided
#'   p-value, the observed mean difference, a confidence interval of level
#'   1 - 2 * alpha, and Welch's degrees of freedom.
#' @export
#'
#' @examples
#' pharma_tost(c(3.1, 3.4, 3.8, 4.0), c(3.0, 3.6, 4.2, 4.8), -2, 2)
#' pharma_tost(response ~ treatment, data = pharma_sample,
#'             low_eqbound = -2, high_eqbound = 2)
pharma_tost <- function(x, ...) {
  UseMethod("pharma_tost")
}

#' @rdname pharma_tost
#' @export
pharma_tost.default <- function(x, y, low_eqbound, high_eqbound,
                                 alpha = 0.05, ...) {
  pharma_log("INFO", "Running pharma_tost.default")
  if (missing(y)) {
    stop("Argument y is required for a two-sample equivalence test")
  }
  check_numeric_vector(x, "x")
  check_numeric_vector(y, "y")
  if (length(x) < 2L || length(y) < 2L) {
    stop("x and y must each contain at least two observations")
  }
  check_numeric_scalar(low_eqbound, "low_eqbound")
  check_numeric_scalar(high_eqbound, "high_eqbound")
  if (low_eqbound >= high_eqbound) {
    stop("low_eqbound must be less than high_eqbound")
  }
  check_numeric_scalar(alpha, "alpha", lower = 0, upper = 0.5)

  n_x <- length(x)
  n_y <- length(y)
  difference <- mean(x) - mean(y)
  mean_variance_x <- stats::var(x) / n_x
  mean_variance_y <- stats::var(y) / n_y
  squared_se <- mean_variance_x + mean_variance_y
  if (!is.finite(squared_se) || squared_se <= 0) {
    stop("x and y must have positive combined sampling variance")
  }

  # Use the Welch-Satterthwaite degrees of freedom for the same variance
  # estimate used in the test statistics and confidence interval.
  df <- squared_se^2 / (
    mean_variance_x^2 / (n_x - 1L) +
      mean_variance_y^2 / (n_y - 1L)
  )
  standard_error <- sqrt(squared_se)
  lower_statistic <- (difference - low_eqbound) / standard_error
  upper_statistic <- (difference - high_eqbound) / standard_error
  lower_p <- stats::pt(lower_statistic, df = df, lower.tail = FALSE)
  upper_p <- stats::pt(upper_statistic, df = df)
  critical_value <- stats::qt(1 - alpha, df = df)

  list(
    statistic = c(t1 = lower_statistic, t2 = upper_statistic),
    p.value = max(lower_p, upper_p),
    diff = difference,
    conf.int = difference + c(-1, 1) * critical_value * standard_error,
    df = df
  )
}

#' @rdname pharma_tost
#' @export
pharma_tost.formula <- function(formula, data, low_eqbound, high_eqbound,
                                 alpha = 0.05, ...) {
  pharma_log("INFO", "Running pharma_tost.formula")
  validate_inputs(data, formula)
  model_data <- stats::model.frame(
    formula, data = data, na.action = stats::na.pass
  )
  if (ncol(model_data) != 2L) {
    stop("formula must specify one response and one grouping variable")
  }
  if (anyNA(model_data)) {
    stop("Variables used by formula contain NA values")
  }

  response <- model_data[[1L]]
  check_numeric_vector(response, "response")
  group <- droplevels(as.factor(model_data[[2L]]))
  if (nlevels(group) != 2L) {
    stop("Grouping variable must have exactly two observed levels")
  }

  observations <- split(response, group)
  pharma_tost.default(
    observations[[1L]], observations[[2L]],
    low_eqbound, high_eqbound, alpha, ...
  )
}
