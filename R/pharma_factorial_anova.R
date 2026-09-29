#' Analyze a balanced, replicated two-factor design
#'
#' Fit an ordinary two-factor ANOVA with both main effects and their
#' interaction. The two factors must be crossed, with the same number of
#' observations (at least two) in every cell.
#'
#' @param formula A two-sided `response ~ factor1 * factor2` formula with an
#'   intercept. Each predictor must be a factor, character, or logical
#'   variable. Convert numeric group codes explicitly with `factor()`.
#' @param data A data frame containing the variables in the model.
#' @param ... Additional arguments passed to `stats::aov`. `subset`,
#'   `weights`, `na.action`, and `offset` are not supported because they
#'   can change the checked population or model.
#'
#' @details
#' Missing model values and non-finite responses are rejected. The balanced
#'   design makes the ordinary sequential sums of squares for the two main
#'   effects and interaction orthogonal. Inference still assumes independent
#'   errors, a common within-cell variance, and a suitable residual
#'   distribution. This helper does not fit repeated observations, covariates,
#'   blocking, or unbalanced factorial designs.
#'
#' @return An `aov` object with estimable main effects, interaction, and
#'   residual error. The main-effect tests average over the other factor.
#' @export
#'
#' @examples
#' example <- data.frame(
#'   treatment = factor(rep(c("A", "B"), each = 4)),
#'   dose = factor(rep(c("Low", "High"), each = 2, times = 2)),
#'   response = c(9, 11, 11, 13, 10, 12, 16, 18)
#' )
#' summary(pharma_factorial_anova(response ~ treatment * dose, example))
pharma_factorial_anova <- function(formula, data, ...) {
  validate_inputs(data, formula)
  dots <- match.call(expand.dots = FALSE)$...
  if (any(names(dots) %in% c("subset", "weights", "na.action", "offset"))) {
    stop("`subset`, `weights`, `na.action`, and `offset` are not supported; ",
         "prepare the complete factorial design before fitting",
         call. = FALSE)
  }

  model_data <- stats::model.frame(
    formula, data = data, na.action = stats::na.pass
  )
  model_terms <- stats::terms(model_data)
  term_order <- attr(model_terms, "order")
  if (ncol(model_data) != 3L ||
      attr(model_terms, "intercept") != 1L ||
      length(term_order) != 3L ||
      !identical(as.integer(term_order), c(1L, 1L, 2L)) ||
      length(attr(model_terms, "offset")) > 0L) {
    stop("A two-factor ANOVA requires response ~ factor1 * factor2 ",
         "with an intercept and no other terms", call. = FALSE)
  }
  if (anyNA(model_data)) {
    stop("Model variables contain NA values; handle them before fitting",
         call. = FALSE)
  }

  response <- model_data[[1L]]
  if (!is.numeric(response) || !is.null(dim(response)) ||
      !all(is.finite(response))) {
    stop("Response must be a finite numeric vector", call. = FALSE)
  }
  predictors <- model_data[2:3]
  if (!all(vapply(predictors, function(x) {
    is.factor(x) || is.character(x) || is.logical(x)
  }, logical(1)))) {
    stop("Both predictors must be categorical; wrap numeric codes in ",
         "factor()", call. = FALSE)
  }

  factors <- lapply(predictors, function(x) droplevels(as.factor(x)))
  if (any(vapply(factors, nlevels, integer(1)) < 2L)) {
    stop("Each factor must have at least two observed levels", call. = FALSE)
  }
  cells <- table(factors[[1L]], factors[[2L]])
  if (any(cells < 2L) || length(unique(as.integer(cells))) != 1L) {
    stop("Every factor combination must have the same number of ",
         "observations, at least two per cell", call. = FALSE)
  }

  stats::aov(formula = formula, data = data, ...)
}
