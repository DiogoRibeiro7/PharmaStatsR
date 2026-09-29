#' Conduct a one-way ANOVA
#'
#' Compare means across the observed levels of one categorical grouping variable
#' with an ordinary, intercept-including, one-way ANOVA.
#'
#' @param formula A two-sided `response ~ group` formula with an intercept.
#'   The group must be a factor, character, or logical variable. Convert numeric
#'   group codes explicitly with `factor()` in the formula or data.
#' @param data A data frame containing the variables in the formula.
#' @param ... Additional arguments passed to `stats::aov`.
#'
#' @details
#' This helper tests equality of group means with the ordinary F statistic.
#' It rejects numeric predictors, multiple terms, interactions, and formulas
#' without an intercept. Missing model values must be handled before fitting.
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
  validate_inputs(data, formula)
  # Retain incomplete analysis rows so the check below can reject them.
  mf <- stats::model.frame(formula, data = data, na.action = stats::na.pass)
  if (anyNA(mf)) {
    stop("Variables in `data` used by `formula` contain NA values; remove or impute them before calling `pharma_anova`")
  }
  model_terms <- stats::terms(mf)
  if (length(attr(model_terms, "term.labels")) != 1L ||
      ncol(mf) != 2L || attr(model_terms, "intercept") != 1L) {
    stop("pharma_anova requires a response ~ one categorical group formula ",
         "with an intercept", call. = FALSE)
  }
  response <- mf[[1L]]
  if (!is.numeric(response) || !is.null(dim(response))) {
    stop("Response variable must be a single numeric vector", call. = FALSE)
  }
  if (!all(is.finite(response))) {
    stop("Response variable must contain only finite values", call. = FALSE)
  }
  group <- mf[[2L]]
  if (!(is.factor(group) || is.character(group) || is.logical(group))) {
    stop("Grouping variable must be categorical; wrap numeric codes in ",
         "factor()", call. = FALSE)
  }
  observed_groups <- droplevels(as.factor(group))
  if (nlevels(observed_groups) < 2L) {
    stop("Grouping variable must have at least two observed levels",
         call. = FALSE)
  }
  # Use the original data so transformed terms such as factor(dose) can be
  # evaluated again by aov() and retain their formula semantics.
  stats::aov(formula = formula, data = data, ...)
}
