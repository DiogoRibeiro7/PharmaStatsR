#' Conduct a one-way ANOVA
#'
#' Provides a thin wrapper around `stats::aov` for comparing means across groups.
#'
#' @param formula A model formula specifying the outcome and group.
#' @param data A data frame containing the variables in the formula.
#' @param ... Additional arguments passed to `stats::aov`.
#'
#' @return An object of class `aov`.
#' @export
#'
#' @examples
#' # Basic usage
#' pharma_anova(response ~ treatment, data = pharma_sample)
#'
#' # Complete workflow with post-hoc tests
#' model <- pharma_anova(response ~ treatment, data = pharma_sample)
#' summary(model)
#' TukeyHSD(model)
pharma_anova <- function(formula, data, ...) {
  pharma_log("INFO", "Running pharma_anova")
  if (!inherits(formula, "formula")) {
    stop("`formula` must be a valid formula, e.g., response ~ group")
  }
  if (!is.data.frame(data)) {
    stop("`data` must be a data frame; got ", class(data)[1])
  }
  check_dataset(data, all.vars(formula))
  mf <- stats::model.frame(formula, data)
  if (anyNA(mf)) {
    stop("Variables in `data` used by `formula` contain NA values; remove or impute them before calling `pharma_anova`")
  }
  terms <- stats::terms(mf)
  if (length(attr(terms, "term.labels")) != 1) {
    stop("`pharma_anova` supports one-way ANOVA with a single grouping variable")
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
  if (nlevels(group) < 2) {
    stop("Grouping variable must have at least two levels; found ", nlevels(group))
  }
  stats::aov(formula = formula, data = mf, ...)
}
