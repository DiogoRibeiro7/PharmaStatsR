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
#' Expanded output names must also be unique; rename colliding covariates or
#' factor levels rather than relying on ambiguous labels. Non-finite generated
#' coding for an observed covariate raises an error identifying that variable.
#' Missing inputs remain allowed. These checks apply to the supplied rows, not
#' unobserved categories; [fit_encoding()] probes every declared level.
#'
#' @param data A `data.frame` containing covariate columns.
#' @param covariates Character vector of unique covariate column names.
#'
#' @return A numeric matrix with one row per input row. Categorical terms may
#'   expand into multiple columns according to R's contrast rules. The first
#'   categorical term uses full indicator coding in this no-intercept design.
#'   The `assign` attribute maps output columns to selected covariates;
#'   `contrasts` records R's contrast specifications. Coding follows current
#'   options and factor attributes; use the saved encoding pair for new data.
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
  design <- stats::model.matrix(~ 0 + ., data = frame)
  if (anyDuplicated(colnames(design))) {
    stop("Model matrix creates ambiguous output column names; rename covariates or levels")
  }
  assignment <- attr(design, "assign")
  for (i in seq_along(covariates)) {
    observed <- !is.na(frame[[i]])
    columns <- which(assignment == i)
    if (any(!is.finite(design[observed, columns, drop = FALSE]))) {
      stop(sprintf(
        "Non-finite model-matrix coding for observed covariate '%s'; check contrasts",
        covariates[i]
      ))
    }
  }
  design
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
#' With `repair_names = TRUE`, selected columns instead receive deterministic,
#' unique syntactic names before reaching the backend. Names are treated
#' literally, including formula operators, backticks, and R evaluation symbols.
#' Values, factor attributes, and row order are unchanged. The caller's data
#' are not modified.
#'
#' Repaired fits remain native `lme` objects. Their formulas, coefficient labels,
#' and stored data use the backend names; `column_map` records the original
#' names, backend names, and roles. Use [predict_covariate_model()] with raw new
#' rows to apply that map. Native [stats::predict()] still expects the backend
#' names. Name repair does not change the model, estimation, or missing-data
#' policy, and does not imply support for formula expressions in column inputs.
#'
#' Use `summary(model)` for the native mixed-model summary and
#' `coef(summary(model))` for its fixed-effect estimates, standard errors,
#' denominator degrees of freedom, t statistics and p-values. Native `nlme`
#' summary defaults apply; ordinary linear-model R-squared is not added.
#'
#' @param data A `data.frame` with response, id and covariate columns.
#' @param response Name of the response variable.
#' @param id Name of the subject ID variable.
#' @param covariates Character vector of unique covariate names.
#' @param repair_names Logical, default `FALSE` to retain strict syntactic-name
#'   validation. `TRUE` repairs the selected names without collisions with
#'   other columns and stores their mapping on the fitted object.
#'
#' @return A native object of class `lme`. With `repair_names = TRUE`, the added
#'   `column_map` data frame contains `role` (`response`, `id`, or `covariate`),
#'   `original`, and `model` columns in response/id/covariate order. Treat this
#'   mapping as fitted output; it is retained by an RDS round trip.
#' @examples
#' df <- data.frame(
#'   SubjectID = rep(1:10, each = 3),
#'   Time = rep(0:2, times = 10),
#'   DV = rnorm(30),
#'   WT = rnorm(30, 70, 5)
#' )
#' fit <- fit_covariate_model(df, "DV", "SubjectID", c("Time", "WT"))
#' summary(fit)
#' coef(summary(fit))
#' names(df)[names(df) == "WT"] <- "body mass"
#' repaired <- fit_covariate_model(df, "DV", "SubjectID", c("Time", "body mass"),
#'   repair_names = TRUE
#' )
#' repaired$column_map
#' predict_covariate_model(repaired, df[1:3, ], level = 0)
#' @seealso [predict_covariate_model()]
#' @export
fit_covariate_model <- function(data, response, id, covariates, repair_names = FALSE) {
  if (!is.logical(repair_names) || length(repair_names) != 1L ||
    is.na(repair_names) || !is.null(dim(repair_names))) {
    stop("`repair_names` must be TRUE or FALSE")
  }
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
  if (repair_names) {
    original <- c(response, id, covariates)
    backend <- make.names(original)
    special <- backend %in% c(".", "...") | grepl("^\\.\\.[0-9]+$", backend)
    backend[special] <- paste0("covariate_column_", which(special))
    # Reserve unselected names too; simultaneous renaming preserves collisions
    # such as original 'body mass' and 'body.mass' as separate columns.
    reserved <- setdiff(names(data), original)
    backend <- utils::tail(make.unique(c(reserved, backend)), length(original))
    column_map <- data.frame(
      role = c("response", "id", rep("covariate", length(covariates))),
      original = original, model = backend, stringsAsFactors = FALSE
    )
    names(data)[match(original, names(data))] <- backend
    response <- backend[1L]
    id <- backend[2L]
    covariates <- backend[-c(1L, 2L)]
  }
  validate_model_names(c(response, id, covariates), syntactic = TRUE)

  if (length(covariates) == 0) {
    fixed_formula <- stats::as.formula(paste(response, "~ 1"))
  } else {
    fixed_formula <- stats::reformulate(covariates, response = response)
  }
  validate_lme_data(data, response, id, covariates, fixed_formula)

  model <- nlme::lme(
    fixed = fixed_formula,
    random = stats::as.formula(paste("~1 |", id)),
    data = data,
    na.action = stats::na.exclude
  )
  if (repair_names) model$column_map <- column_map
  model
}
