# Shared checks for tabular inputs and numeric vectors.
is_numeric_vector <- function(x) {
  is.numeric(x) && !is.complex(x) && is.null(dim(x))
}

validate_data_frame_names <- function(data) {
  if (!is.data.frame(data)) {
    stop("`data` must be a data.frame")
  }
  if (anyNA(names(data)) || any(names(data) == "")) {
    stop("`data` must have nonmissing, nonempty column names")
  }
  if (anyDuplicated(names(data))) {
    stop("`data` must have unique column names")
  }
  invisible(TRUE)
}

validate_preprocessing_vars <- function(data, vars, numeric_only = TRUE) {
  validate_data_frame_names(data)
  if (length(vars) == 0L) {
    return(invisible(TRUE))
  }
  if (!is.character(vars) || !is.null(dim(vars)) || anyNA(vars) ||
    anyDuplicated(vars)) {
    stop("`vars` must be a character vector of unique column names")
  }
  if (!all(vars %in% names(data))) {
    missing <- setdiff(vars, names(data))
    stop(sprintf("Variables not found: %s", paste(missing, collapse = ", ")))
  }

  for (var in vars) {
    column <- data[[var]]
    is_numeric <- is_numeric_vector(column)
    if (numeric_only && !is_numeric) {
      stop(sprintf(
        "Variable '%s' must be numeric, real-valued, and one-dimensional", var
      ))
    }
    categorical <- is.null(dim(column)) &&
      (is.character(column) || is.logical(column) || is.factor(column))
    if (!is_numeric && !categorical) {
      stop(sprintf(
        "Variable '%s' must be a numeric, logical, character, or factor vector",
        var
      ))
    }
    if (is_numeric && any(is.infinite(column))) {
      stop(sprintf("Variable '%s' contains infinite values", var))
    }
  }
  invisible(TRUE)
}
