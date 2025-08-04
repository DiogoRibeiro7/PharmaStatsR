#' Conduct a two-sample t-test
#'
#' Provides a simple wrapper around `stats::t.test` for comparing two numeric
#' samples. The function returns the full result from `stats::t.test` so users
#' can inspect p-values and confidence intervals.
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
#' # Vector interface
#' pharma_t_test(rnorm(10), rnorm(10))
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
  stats::t.test(x, y, ...)
}

#' @rdname pharma_t_test
#' @export
pharma_t_test.formula <- function(formula, data, ...) {
  pharma_log("INFO", "Running pharma_t_test.formula")
  if (!inherits(formula, "formula")) {
    stop("`formula` must be a valid formula, e.g., response ~ group")
  }
  if (!is.data.frame(data)) {
    stop("`data` must be a data frame; got ", class(data)[1])
  }
  check_dataset(data, all.vars(formula))
  mf <- stats::model.frame(formula, data)
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
