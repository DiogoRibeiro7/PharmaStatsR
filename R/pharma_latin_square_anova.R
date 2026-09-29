#' Analyze a Latin square design
#'
#' Fit an additive ANOVA for a complete Latin square with categorical treatment,
#' row, and column effects.
#'
#' @param formula A two-sided `response ~ treatment + row + column` formula
#'   with an intercept and three main effects in that order. Each design term
#'   must be a factor, character, or logical variable. Wrap numeric identifiers
#'   in `factor()` in the formula or data.
#' @param data A data frame containing the variables in the formula.
#' @param ... Additional arguments passed to `stats::aov`. `subset`,
#'   `weights`, and `na.action` are not supported because they can alter
#'   the checked design or its analysis population.
#'
#' @details
#' There must be the same number of observed row, column, and treatment levels,
#'   at least three of each. Every row-column cell must occur once, and each
#'   treatment must occur once in every row and column. Missing model values
#'   and non-finite responses are rejected. This additive model has no
#'   separately estimable interactions in a single unreplicated square.
#'
#' @return An object of class `aov`.
#' @export
#'
#' @examples
#' pharma_latin_square_anova(response ~ treatment + row + column, data = pharma_latin_square)
pharma_latin_square_anova <- function(formula, data, ...) {
  validate_inputs(data, formula)
  dots <- match.call(expand.dots = FALSE)$...
  if (any(names(dots) %in% c("subset", "weights", "na.action"))) {
    stop("`subset`, `weights`, and `na.action` are not supported; ",
         "prepare the complete square before fitting", call. = FALSE)
  }

  mf <- stats::model.frame(formula, data = data, na.action = stats::na.pass)
  model_terms <- stats::terms(mf)
  if (length(attr(model_terms, "term.labels")) != 3L ||
      ncol(mf) != 4L ||
      attr(model_terms, "intercept") != 1L ||
      any(attr(model_terms, "order") != 1L)) {
    stop("A Latin square requires response ~ treatment + row + column ",
         "with an intercept and three main effects", call. = FALSE)
  }
  if (anyNA(mf)) {
    stop("Model variables contain NA values; remove or impute them before ",
         "calling `pharma_latin_square_anova()`", call. = FALSE)
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
    stop("Treatment, row, and column must be categorical; wrap numeric ",
         "identifiers in factor()", call. = FALSE)
  }
  groups <- lapply(groups, function(x) droplevels(as.factor(x)))
  sizes <- vapply(groups, nlevels, integer(1))
  if (length(unique(sizes)) != 1L || sizes[1L] < 3L) {
    stop("Treatment, row, and column must have the same number of ",
         "observed levels, at least three", call. = FALSE)
  }
  n <- sizes[1L]
  if (nrow(mf) != n * n ||
      any(table(groups[[2L]], groups[[3L]]) != 1L) ||
      any(table(groups[[1L]], groups[[2L]]) != 1L) ||
      any(table(groups[[1L]], groups[[3L]]) != 1L)) {
    stop("The design must have one observation per row-column cell ",
         "and each treatment once per row and column", call. = FALSE)
  }

  stats::aov(formula = formula, data = data, ...)
}
