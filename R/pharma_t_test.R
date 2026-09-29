#' Perform a two-sample t-test
#'
#' Provides a flexible interface for comparing two numeric samples, supporting
#' both vector and formula interfaces. The function returns the full result from
#' `stats::t.test` with p-values and confidence intervals.
#'
#' @section Methods:
#' This function is S3 generic with two methods:
#' \describe{
#'   \item{default}{Vector interface for direct comparison of two numeric vectors.}
#'   \item{formula}{Formula interface for comparing groups within a data frame.}
#' }
#'
#' @param x Numeric vector of observations from the first group.
#' @param y Numeric vector of observations from the second group.
#' @param formula A model formula specifying the response and grouping variable.
#' @param data A data frame containing the variables in the formula.
#' @param ... Additional arguments passed to `stats::t.test`.
#'
#' @return A `htest` object produced by `stats::t.test`.
#' @export
#'
#' @examples
#' # Comprehensive example showing a complete analysis
#' # 1. Data preparation
#' grp_a <- rnorm(20, mean = 5, sd = 1)
#' grp_b <- rnorm(20, mean = 5.5, sd = 1)
#'
#' # 2. Statistical test
#' result <- pharma_t_test(grp_a, grp_b)
#'
#' # 3. Interpretation
#' if (result$p.value < 0.05) {
#'   cat("Significant difference detected\n")
#' } else {
#'   cat("No significant difference\n")
#' }
#'
#' # 4. Visualization
#' boxplot(list(A = grp_a, B = grp_b), main = "Group Comparison")
#'
#' # Formula interface
#' pharma_t_test(response ~ treatment, data = pharma_sample)
pharma_t_test <- function(x, ...) {
  UseMethod("pharma_t_test")
}

#' @rdname pharma_t_test
#' @export
pharma_t_test.default <- function(x, y, ...) {
  pharma_log("INFO", "Running pharma_t_test.default")
  if (missing(y)) {
    stop("Argument `y` is required for a two-sample test; supply a second numeric vector")
  }
  check_numeric_vector(x, "x")
  check_numeric_vector(y, "y")
  if (length(x) < 2 || length(y) < 2) {
    stop("`x` and `y` must each contain at least two observations")
  }
  if (any(abs(c(x, y)) > 1e6)) {
    warning("extreme values detected; results may be unstable")
  }
  stats::t.test(x, y, ...)
}

#' @rdname pharma_t_test
#' @export
pharma_t_test.formula <- function(formula, data, ...) {
  pharma_log("INFO", "Running pharma_t_test.formula")
  validate_inputs(data = data, formula = formula)
  # Retain incomplete analysis rows so the check below can reject them.
  mf <- stats::model.frame(formula, data = data, na.action = stats::na.pass)
  if (ncol(mf) != 2) {
    stop("`formula` must specify one response and one grouping variable")
  }
  if (anyNA(mf)) {
    stop("Variables in `data` used by `formula` contain NA values; remove or impute them before calling `pharma_t_test`")
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
  stats::t.test(formula, data = mf, ...)
}
