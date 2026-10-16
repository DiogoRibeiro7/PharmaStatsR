#' Fit reusable numeric imputation parameters
#'
#' Estimates a mean or median from observed training values in each selected
#' column. The returned parameter table can be saved and applied to training,
#' validation, or future data with [apply_imputation()]. No input data are changed.
#'
#' Split data before fitting. For cross-validation, fit a separate parameter
#' table using only the training rows of each fold. Keep repeated observations
#' from a subject together when that is the intended validation unit. These
#' helpers do not add fold-specific preprocessing to [screen_covariates_lasso()].
#'
#' `NA` and `NaN` are omitted when fitting. Selected columns must be real numeric
#' vectors without infinite values and must each contain at least one observed
#' value. Singleton and constant columns are allowed. An entirely missing
#' training column raises an error because no replacement can be estimated;
#' this differs from the warning-and-leave-missing behavior of [impute_mean()]
#' and [impute_median()]. Single-value imputation does not quantify missing-data
#' uncertainty or make assumptions about missingness valid.
#'
#' @param data A training `data.frame` with unique, nonmissing, nonempty names.
#' @param vars Character vector of unique numeric column names. Names match
#'   literally. `character(0)` or `NULL` returns an empty parameter table.
#' @param method Summary to estimate: `"mean"` (default) or `"median"`.
#'
#' @return A plain data frame with columns `var` (character), `value` (finite
#'   numeric replacement), and `method` (character), in `vars` order. It can be
#'   persisted with [base::saveRDS()] and [base::readRDS()]. The table contains
#'   no training rows; `method` records how each replacement was estimated.
#' @examples
#' training <- data.frame(x = c(1, NA, 3, 8))
#' params <- fit_imputation(training, "x")
#' params # observed training mean is 4
#' apply_imputation(training, params)
#' validation <- data.frame(x = c(NA, 100))
#' apply_imputation(validation, params) # fills with 4, not 100
#' @seealso [apply_imputation()], [impute_mean()], [impute_median()],
#'   [center_scale()], [apply_center_scale()], [screen_covariates_lasso_imputed()]
#' @export
fit_imputation <- function(data, vars, method = c("mean", "median")) {
  method <- match.arg(method)
  validate_preprocessing_vars(data, vars)
  summary_function <- if (method == "mean") mean else stats::median
  values <- vapply(vars, function(variable) {
    column <- data[[variable]]
    if (all(is.na(column))) {
      stop(sprintf(
        "Variable '%s' needs at least one observed training value", variable
      ))
    }
    value <- summary_function(column, na.rm = TRUE)
    if (!is.finite(value)) {
      stop(sprintf("Cannot compute a finite imputation value for '%s'", variable))
    }
    as.numeric(value)
  }, numeric(1))

  data.frame(
    var = as.character(vars), value = unname(values),
    method = rep(method, length(vars)), stringsAsFactors = FALSE
  )
}

#' Apply saved numeric imputation parameters
#'
#' Fills missing values (`NA` or `NaN`) using previously fitted replacements,
#' without estimating anything from the supplied data. Parameter rows match
#' columns by their literal names. Observed values are unchanged.
#'
#' Selected columns must be real numeric vectors without infinite values.
#' Empty, singleton, constant, or entirely missing new columns are allowed;
#' they need not support fitting their own replacements. Integer columns with
#' missing entries may be promoted to double to preserve fractional values.
#'
#' @param data A `data.frame` containing the numeric columns to impute.
#' @param params A data frame with `var` and `value` columns, such as the result
#'   of [fit_imputation()]. `var` must contain unique, nonmissing, nonempty
#'   character names; `value` must contain finite real numbers. Additional
#'   columns, including the fitter's `method` metadata, are ignored. A valid
#'   zero-row parameter table leaves the data unchanged.
#'
#' @return A data frame with only selected missing entries filled. Row order,
#'   row names, column order, and unselected columns are preserved. The input
#'   data and parameter table are not modified.
#' @examples
#' params <- fit_imputation(data.frame(x = c(1, 3, 8)), "x", "median")
#' apply_imputation(data.frame(x = c(NA, 100, NaN)), params)
#' @seealso [fit_imputation()], [apply_center_scale()]
#' @export
apply_imputation <- function(data, params) {
  validate_imputation_params(params)
  validate_preprocessing_vars(data, params$var)
  for (i in seq_len(nrow(params))) {
    variable <- params$var[i]
    missing <- is.na(data[[variable]])
    if (any(missing)) {
      data[[variable]][missing] <- params$value[i]
    }
  }
  data
}

validate_imputation_params <- function(params) {
  if (!is.data.frame(params)) {
    stop("`params` must be a data.frame")
  }
  if (anyNA(names(params)) || any(names(params) == "") ||
    anyDuplicated(names(params))) {
    stop("`params` must have unique, nonmissing, nonempty column names")
  }
  if (!all(c("var", "value") %in% names(params))) {
    stop("`params` must contain 'var' and 'value' columns")
  }
  if (!is.character(params$var) || !is.null(dim(params$var)) ||
    anyNA(params$var) || any(params$var == "") || anyDuplicated(params$var)) {
    stop("`params$var` must contain unique, nonmissing, nonempty variable names")
  }
  if (!is_numeric_vector(params$value) || any(!is.finite(params$value))) {
    stop("`params$value` must contain finite real numbers")
  }
  invisible(TRUE)
}
