validate_knn_model <- function(model) {
  fields <- c(
    "version", "vars", "predictors", "k", "weights", "schema",
    "donor_predictors", "donor_targets"
  )
  invalid <- function() stop("Invalid saved kNN model; refit with fit_knn_imputation()")
  if (!is.list(model) || !identical(names(model), fields) ||
    !identical(model$version, 1L)) {
    invalid()
  }
  validate_knn_names(model$vars, "model$vars")
  validate_knn_names(model$predictors, "model$predictors")
  validate_knn_k(model$k)
  weights <- model$weights
  if (!is_numeric_vector(weights) || any(!is.finite(weights)) ||
    any(weights <= 0) || !identical(names(weights), model$predictors)) {
    invalid()
  }
  validate_preprocessing_vars(model$donor_targets, model$vars)
  if (!identical(names(model$donor_targets), model$vars) ||
    any(vapply(model$donor_targets, function(x) all(is.na(x)), logical(1)))) {
    invalid()
  }
  if (!is.list(model$schema) || !identical(names(model$schema), model$predictors) ||
    !is.list(model$donor_predictors) ||
    !identical(names(model$donor_predictors), model$predictors)) {
    invalid()
  }
  n <- nrow(model$donor_targets)
  for (variable in model$vars) {
    if (length(setdiff(model$predictors, variable)) == 0L) invalid()
  }
  for (variable in model$predictors) {
    schema <- model$schema[[variable]]
    if (!is.list(schema) ||
      !identical(names(schema), c("kind", "levels", "offset", "span", "divisor"))) {
      invalid()
    }
    kind <- schema$kind
    if (!is.character(kind) || length(kind) != 1L || is.na(kind) ||
      !kind %in% c("numeric", "ordered", "logical", "nominal")) {
      invalid()
    }
    for (field in c("offset", "span", "divisor")) {
      value <- schema[[field]]
      if (!is_numeric_vector(value) || length(value) != 1L || !is.finite(value)) invalid()
    }
    if (schema$span < 0 || !schema$divisor %in% c(1, 2)) invalid()
    if (kind == "ordered") {
      if (!is.character(schema$levels) || !is.null(dim(schema$levels)) ||
        anyNA(schema$levels) || anyDuplicated(schema$levels)) {
        invalid()
      }
    } else if (!is.null(schema$levels)) invalid()
    column <- model$donor_predictors[[variable]]
    if (length(column) != n || !is.null(dim(column))) invalid()
    if (kind %in% c("numeric", "ordered")) {
      if (!is_numeric_vector(column) || any(is.infinite(column)) ||
        any(column < 0 | column > 1, na.rm = TRUE)) {
        invalid()
      }
    } else {
      if (!is.character(column)) invalid()
      if (kind == "logical" && any(!is.na(column) & !column %in% c("TRUE", "FALSE"))) invalid()
    }
  }
  invisible(TRUE)
}
