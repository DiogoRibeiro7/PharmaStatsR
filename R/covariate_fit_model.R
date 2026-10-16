#' Prepare design matrix for covariates
#'
#' Converts character columns to factors and returns a model matrix without an
#' intercept. Input row order and row names are preserved. Missing values stay
#' missing rather than silently dropping rows, regardless of the global
#' `na.action` option. An empty selection returns a matrix with zero columns.
#'
#' Candidates may be real numeric, logical, character, or factor vectors.
#' Infinite values, ambiguous names, and unsupported column types are rejected.
#' Factors retain their declared levels, including unused ones, and require at
#' least two levels for contrast coding. Character columns derive their levels
#' from observed values. Constant numeric columns are allowed; this helper does
#' not guarantee a full-rank design. Columns named `...` or `..1`, `..2`, etc.
#' must be renamed because R treats these as special evaluation symbols.
#'
#' @param data A `data.frame` containing covariate columns.
#' @param covariates Character vector of unique covariate column names.
#'
#' @return A numeric matrix with one row per input row. Categorical terms may
#'   expand into multiple columns according to R's contrast rules. The first
#'   categorical term uses full indicator coding in this no-intercept design.
#' @examples
#' df <- data.frame(id = 1:3, age = c(20, 25, 30), sex = c("M", "F", "F"))
#' prepare_model_matrix(df, c("age", "sex"))
#' @seealso [fit_encoding()], [apply_encoding()] for saved training coding.
#' @export
prepare_model_matrix <- function(data, covariates) {
  covariates <- validate_model_covariates(data, covariates)
  if (length(covariates) == 0L) {
    return(matrix(
      numeric(0),
      nrow = nrow(data), ncol = 0L,
      dimnames = list(rownames(data), NULL)
    ))
  }
  validate_model_vectors(data, covariates)
  validate_model_names(covariates)
  frame <- prepare_covariate_frame(data, covariates)
  frame <- stats::model.frame(
    ~ 0 + .,
    data = frame, na.action = stats::na.pass
  )
  stats::model.matrix(~ 0 + ., data = frame)
}

#' Fit mixed-effects model with covariates
#'
#' Fits a linear mixed-effects model with a random subject intercept using
#' `nlme::lme` and its default REML estimation. Covariates enter as additive
#' main effects; an empty selection fits an intercept-only fixed-effects model.
#'
#' The response must be a real numeric vector. Covariates and identifiers may
#' be real numeric, logical, character, or factor vectors. Missing response,
#' identifier, or covariate values are excluded with `na.exclude`. Numeric
#' values must be finite on retained rows. At least three rows, two subjects,
#' and one subject with repeated observations must remain. The response must
#' vary, the fixed-effects design must have full column rank, and there must
#' be more retained rows than fixed-effects coefficients. These checks do not
#' guarantee optimizer convergence.
#'
#' Response, identifier, and covariate roles must be distinct. Duplicate names
#' and selections are rejected. The `nlme` backend requires syntactic R column
#' names: rename names containing spaces or formula operators before fitting.
#' The names `.`, `...`, and `..1`, `..2`, etc. are also unsupported. No column
#' name is accepted as a formula expression.
#'
#' @param data A `data.frame` with response, id and covariate columns.
#' @param response Name of the response variable.
#' @param id Name of the subject ID variable.
#' @param covariates Character vector of unique covariate names.
#'
#' @return An object of class `lme`.
#' @examples
#' df <- data.frame(
#'   SubjectID = rep(1:10, each = 3),
#'   Time = rep(0:2, times = 10),
#'   DV = rnorm(30),
#'   WT = rnorm(30, 70, 5)
#' )
#' fit_covariate_model(df, "DV", "SubjectID", c("Time", "WT"))
#' @export
fit_covariate_model <- function(data, response, id, covariates) {
  covariates <- validate_model_covariates(data, covariates)
  for (name in list(response = response, id = id)) {
    if (!is.character(name) || length(name) != 1L || !is.null(dim(name)) ||
      is.na(name)) {
      stop("`response` and `id` must each name one column")
    }
  }
  if (!all(c(response, id) %in% names(data))) {
    missing <- setdiff(c(response, id), names(data))
    stop(sprintf("Variables not found: %s", paste(missing, collapse = ", ")))
  }
  if (response == id || response %in% covariates || id %in% covariates) {
    stop("Response, subject identifier, and covariates must be distinct")
  }
  validate_model_names(c(response, id, covariates), syntactic = TRUE)

  if (length(covariates) == 0) {
    fixed_formula <- stats::as.formula(paste(response, "~ 1"))
  } else {
    fixed_formula <- stats::reformulate(covariates, response = response)
  }
  validate_lme_data(data, response, id, covariates, fixed_formula)

  nlme::lme(
    fixed = fixed_formula,
    random = stats::as.formula(paste("~1 |", id)),
    data = data,
    na.action = stats::na.exclude
  )
}
