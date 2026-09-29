#' Analyze a balanced 2x2 crossover design
#'
#' Fit an additive ANOVA with categorical treatment and period effects and
#' a fixed effect for each subject in a complete AB/BA crossover.
#'
#' @param formula A two-sided `response ~ treatment + period + subject`
#'   formula with an intercept and three main effects in that order. The
#'   design variables must be factors, characters, or logicals; wrap numeric
#'   identifiers in `factor()` in the formula or data.
#' @param data A data frame containing the variables in the formula.
#' @param ... Additional arguments passed to `stats::aov`. `subset`,
#'   `weights`, and `na.action` are not supported because they can change
#'   the checked design or analysis population.
#'
#' @details
#' Each subject must have exactly one observation in each of two periods and
#'   must receive each of two treatments once. At least four subjects are
#'   required, with equal numbers assigned to the AB and BA sequences.
#'   Missing model values and non-finite responses are rejected. This simple
#'   additive model does not estimate carryover or sequence effects separately
#'   from treatment and subject effects.
#'
#' @return An object of class `aov`.
#' @export
#'
#' @examples
#' pharma_crossover_anova(response ~ treatment + period + subject, data = pharma_crossover)
pharma_crossover_anova <- function(formula, data, ...) {
  validate_inputs(data, formula)
  dots <- match.call(expand.dots = FALSE)$...
  if (any(names(dots) %in% c("subset", "weights", "na.action"))) {
    stop("`subset`, `weights`, and `na.action` are not supported; ",
         "prepare the complete crossover before fitting", call. = FALSE)
  }

  mf <- stats::model.frame(formula, data = data, na.action = stats::na.pass)
  model_terms <- stats::terms(mf)
  if (length(attr(model_terms, "term.labels")) != 3L ||
      ncol(mf) != 4L ||
      attr(model_terms, "intercept") != 1L ||
      any(attr(model_terms, "order") != 1L)) {
    stop("A 2x2 crossover requires response ~ treatment + period + subject ",
         "with an intercept and three main effects", call. = FALSE)
  }
  if (anyNA(mf)) {
    stop("Model variables contain NA values; remove or impute them before ",
         "calling `pharma_crossover_anova()`", call. = FALSE)
  }
  response <- mf[[1L]]
  if (!is.numeric(response) || !is.null(dim(response)) ||
      !all(is.finite(response))) {
    stop("Response must be a finite numeric vector", call. = FALSE)
  }

  groups <- mf[2:4]
  if (!all(vapply(groups, function(x) {
    is.factor(x) || is.character(x) || is.logical(x)
  }, logical(1)))) {
    stop("Treatment, period, and subject must be categorical; wrap numeric ",
         "identifiers in factor()", call. = FALSE)
  }
  groups <- lapply(groups, function(x) droplevels(as.factor(x)))
  treatment <- groups[[1L]]
  period <- groups[[2L]]
  subject <- groups[[3L]]
  if (nlevels(treatment) != 2L || nlevels(period) != 2L) {
    stop("A 2x2 crossover requires exactly two observed treatments and ",
         "two observed periods", call. = FALSE)
  }
  n_subjects <- nlevels(subject)
  if (n_subjects < 4L || n_subjects %% 2L != 0L) {
    stop("A balanced crossover requires an even number of subjects, ",
         "at least four", call. = FALSE)
  }
  if (nrow(mf) != 2L * n_subjects ||
      any(table(subject, period) != 1L) ||
      any(table(subject, treatment) != 1L)) {
    stop("Each subject must have one observation in each period ",
         "and receive both treatments", call. = FALSE)
  }
  first_period <- period == levels(period)[1L]
  if (any(table(treatment[first_period]) != n_subjects / 2L)) {
    stop("The AB and BA treatment sequences must contain equal numbers ",
         "of subjects", call. = FALSE)
  }

  stats::aov(formula = formula, data = data, ...)
}
