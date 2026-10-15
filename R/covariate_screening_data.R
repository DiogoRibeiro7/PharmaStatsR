# Prepare a common analysis cohort for AIC/BIC screening. Internal names keep
# user-supplied column names out of formula parsing and stepwise term updates.
prepare_screening_data <- function(data, response, covariates) {
  validate_data_frame_names(data)
  if (!is.character(response) || length(response) != 1L ||
    !is.null(dim(response)) || is.na(response) ||
    !response %in% names(data)) {
    stop("`response` column not found")
  }
  if (is.null(covariates)) {
    covariates <- character(0)
  }
  if (!is.character(covariates) || !is.null(dim(covariates)) ||
    anyNA(covariates) || anyDuplicated(covariates)) {
    stop("`covariates` must be a character vector of unique column names")
  }
  if (!all(covariates %in% names(data))) {
    missing <- setdiff(covariates, names(data))
    stop(sprintf("Covariates not found: %s", paste(missing, collapse = ", ")))
  }
  if (response %in% covariates) {
    stop("`response` cannot also be a candidate covariate")
  }
  if (length(covariates) == 0L) {
    return(NULL)
  }

  if (!is_numeric_vector(data[[response]])) {
    stop("`response` must be a real numeric vector")
  }
  for (v in covariates) {
    column <- data[[v]]
    categorical <- is.null(dim(column)) &&
      (is.factor(column) || is.character(column) || is.logical(column))
    if (!is_numeric_vector(column) && !categorical) {
      stop(sprintf(
        "Covariate '%s' must be numeric, logical, character, or factor vector",
        v
      ))
    }
  }

  data <- data[c(response, covariates)]
  data <- data[stats::complete.cases(data), , drop = FALSE]
  if (nrow(data) < 3L) {
    stop("At least three complete-case rows are required")
  }
  for (v in names(data)) {
    column <- data[[v]]
    if (is_numeric_vector(column) && any(!is.finite(column))) {
      stop(sprintf("Variable '%s' must be finite on complete-case rows", v))
    }
    if (length(unique(column)) < 2L) {
      stop(sprintf("Variable '%s' is constant on complete-case rows", v))
    }
    if (is.character(column)) {
      data[[v]] <- factor(column)
    }
  }
  data <- droplevels(data)
  names(data) <- c(
    ".screen_response", paste0(".screen_covariate_", seq_along(covariates))
  )
  data
}
