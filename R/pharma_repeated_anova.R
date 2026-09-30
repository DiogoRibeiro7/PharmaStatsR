#' Analyze a complete two-condition repeated-measures design
#'
#' Fit a one-factor within-subject ANOVA to paired observations. Each
#' subject must contribute exactly one observation in each condition.
#'
#' @param formula A two-sided `response ~ condition + Error(subject)` formula
#'   with an intercept. `condition` and `subject` must be factor columns;
#'   convert numeric identifiers explicitly with `factor()`.
#' @param data A data frame with a finite numeric response and complete pairs.
#' @param ... Additional arguments passed to `stats::aov`. `subset`,
#'   `weights`, `na.action`, and `offset` are not supported because they can
#'   change the checked population or model.
#'
#' @details
#' The two-level condition effect is tested against the variation in paired
#' differences across subjects. There must be at least three observed subjects
#' and positive, finite variance in those differences. Missing values,
#' duplicate subject-condition pairs, and incomplete pairs are rejected.
#' Inference assumes independent subjects and a suitable distribution of
#' within-subject differences. This helper does not fit covariates, multiple
#' within-subject factors, unequal replication, or incomplete follow-up.
#'
#' @return An `aovlist` with subject and within-subject error strata. The
#'   condition F test is in `summary(fit)[["Error: Within"]][[1L]]`.
#' @export
#'
#' @examples
#' paired <- transform(pharma_repeated,
#'   subject = factor(subject), condition = factor(condition))
#' fit <- pharma_repeated_anova(response ~ condition + Error(subject), paired)
#' summary(fit)
pharma_repeated_anova <- function(formula, data, ...) {
  validate_inputs(data, formula)
  dots <- match.call(expand.dots = FALSE)$...
  if (any(names(dots) %in% c("subset", "weights", "na.action", "offset"))) {
    stop("`subset`, `weights`, `na.action`, and `offset` are not supported; ",
         "prepare the complete paired design before fitting", call. = FALSE)
  }

  if (length(formula) != 3L) {
    stop("Use response ~ condition + Error(subject) with simple column names ",
         "and an intercept", call. = FALSE)
  }
  rhs <- formula[[3L]]
  if (!is.symbol(formula[[2L]]) || !is.call(rhs) ||
      length(rhs) != 3L || !identical(rhs[[1L]], as.name("+")) ||
      !is.symbol(rhs[[2L]]) || !is.call(rhs[[3L]]) ||
      length(rhs[[3L]]) != 2L ||
      !identical(rhs[[3L]][[1L]], as.name("Error")) ||
      !is.symbol(rhs[[3L]][[2L]])) {
    stop("Use response ~ condition + Error(subject) with simple column names ",
         "and an intercept", call. = FALSE)
  }
  columns <- c(as.character(formula[[2L]]), as.character(rhs[[2L]]),
               as.character(rhs[[3L]][[2L]]))
  if (anyDuplicated(columns)) {
    stop("Response, condition, and subject must be distinct columns",
         call. = FALSE)
  }
  model_data <- data[, columns, drop = FALSE]
  if (anyNA(model_data)) {
    stop("Model variables contain NA values; handle them before fitting",
         call. = FALSE)
  }

  response <- model_data[[1L]]
  condition <- model_data[[2L]]
  subject <- model_data[[3L]]
  if (!is.numeric(response) || !is.null(dim(response)) ||
      !all(is.finite(response))) {
    stop("Response must be a finite numeric vector", call. = FALSE)
  }
  if (!is.factor(condition) || !is.factor(subject)) {
    stop("Condition and subject must be factors; wrap numeric IDs in factor()",
         call. = FALSE)
  }
  condition <- droplevels(condition)
  subject <- droplevels(subject)
  if (nlevels(condition) != 2L || nlevels(subject) < 3L) {
    stop("Design requires two observed conditions and at least three subjects",
         call. = FALSE)
  }
  if (any(table(subject, condition) != 1L)) {
    stop("Each subject must have exactly one observation in each condition",
         call. = FALSE)
  }

  paired <- tapply(response, list(subject, condition), identity)
  differences <- paired[, 2L] - paired[, 1L]
  difference_variance <- stats::var(differences)
  if (!is.finite(difference_variance) || difference_variance <= 0) {
    stop("Paired differences must have positive finite variance",
         call. = FALSE)
  }

  fit_data <- data
  fit_data[[columns[[2L]]]] <- condition
  fit_data[[columns[[3L]]]] <- subject
  stats::aov(formula = formula, data = fit_data, ...)
}
