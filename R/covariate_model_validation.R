validate_model_covariates <- function(data, covariates) {
  validate_data_frame_names(data)
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
  unname(covariates)
}

validate_model_vectors <- function(data, vars) {
  for (v in vars) {
    column <- data[[v]]
    categorical <- is.null(dim(column)) &&
      (is.factor(column) || is.character(column) || is.logical(column))
    if (!is_numeric_vector(column) && !categorical) {
      stop(sprintf(
        "Variable '%s' must be a numeric, logical, character, or factor vector",
        v
      ))
    }
  }
  invisible(TRUE)
}

validate_model_names <- function(vars, syntactic = FALSE) {
  invalid <- vars == "..." | grepl("^\\.\\.[0-9]+$", vars)
  if (syntactic) {
    invalid <- invalid | make.names(vars) != vars | vars == "."
  }
  if (any(invalid)) {
    stop(sprintf(
      "Rename unsupported model column names before fitting: %s",
      paste(vars[invalid], collapse = ", ")
    ))
  }
  invisible(TRUE)
}

prepare_covariate_frame <- function(data, covariates) {
  frame <- data[covariates]
  for (v in covariates) {
    column <- frame[[v]]
    if (is.character(column)) {
      column <- factor(column)
    }
    if (is.factor(column) && nlevels(column) < 2L) {
      stop(sprintf("Covariate '%s' needs at least two factor levels", v))
    }
    if (is_numeric_vector(column) && any(is.infinite(column))) {
      stop(sprintf("Variable '%s' contains infinite values", v))
    }
    frame[[v]] <- column
  }
  frame
}

validate_lme_data <- function(data, response, id, covariates, fixed_formula) {
  if (!is_numeric_vector(data[[response]])) {
    stop("`response` must be a real numeric vector")
  }
  vars <- c(response, id, covariates)
  validate_model_vectors(data, vars)
  retained <- data[stats::complete.cases(data[vars]), vars, drop = FALSE]
  if (nrow(retained) < 3L) {
    stop("At least three complete-case rows are required")
  }
  for (v in vars) {
    column <- retained[[v]]
    if (is_numeric_vector(column) && any(!is.finite(column))) {
      stop(sprintf("Variable '%s' must be finite on complete-case rows", v))
    }
  }
  if (length(unique(retained[[response]])) < 2L) {
    stop("`response` must vary on complete-case rows")
  }
  subjects <- retained[[id]]
  if (length(unique(subjects)) < 2L) {
    stop("At least two subjects are required on complete-case rows")
  }
  if (!anyDuplicated(subjects)) {
    stop("At least one subject must have repeated observations")
  }

  # Use the same factor-level dropping as the backend's model frame.
  frame <- stats::model.frame(
    fixed_formula,
    data = retained, na.action = stats::na.pass,
    drop.unused.levels = TRUE
  )
  frame[covariates] <- prepare_covariate_frame(frame, covariates)
  design <- stats::model.matrix(fixed_formula, data = frame)
  if (qr(design)$rank < ncol(design)) {
    stop("Fixed-effects design is rank deficient; remove redundant covariates")
  }
  if (nrow(design) <= ncol(design)) {
    stop("More complete-case rows than fixed-effects coefficients are required")
  }
  invisible(TRUE)
}
