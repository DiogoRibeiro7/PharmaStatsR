#' Fit reusable covariate encoding
#'
#' Saves the levels, numeric coding, and column order of an additive,
#' no-intercept model matrix. Apply the recipe to training or future data with
#' [apply_encoding()]. Numeric columns pass through without scaling or
#' imputation. This is an experimental API.
#'
#' Fit after splitting data, separately inside each training fold. Character
#' levels are learned from the training values. Factors retain their declared
#' levels, including unused levels: declare these from a prespecified schema
#' or training data, not by inspecting held-out values. Logical columns always
#' have `FALSE` and `TRUE` levels. Categorical columns need at least two levels;
#' explicit `NA` factor levels are unsupported (ordinary missing values are
#' allowed).
#'
#' Coding follows [prepare_model_matrix()] at fitting time, including ordered
#' factors, factor contrasts, and the current `contrasts` option. The recipe
#' stores the resulting numeric coding, so applying it does not reevaluate
#' contrast functions or consult later contrast options. No training rows,
#' formulas, functions, or environments are stored. Ambiguous output column
#' names raise an error.
#'
#' @param data A training `data.frame` with unique, nonmissing, nonempty names.
#' @param covariates Character vector of unique column names, matched literally.
#'   Columns must be real numeric, logical, character, or factor vectors.
#'   `character(0)` or `NULL` produces an empty recipe. Names `...` and `..1`
#'   (and other double-dot numbers) are unsupported, as in
#'   [prepare_model_matrix()].
#'
#' @return A plain list with `version` (currently `1L`), `variables` (a named
#'   list of variable specifications), and `columns` (ordered output names).
#'   Each specification contains `kind`, `columns`, and `coding`: a numeric
#'   matrix whose row names are levels, or `NULL` for numeric variables.
#'   Save and reload with [base::saveRDS()] and [base::readRDS()]. Treat the
#'   recipe as fitted output rather than editing its contents.
#' @examples
#' training <- data.frame(x = c(1, 2, 3), group = c("A", "B", "A"))
#' recipe <- fit_encoding(training, c("x", "group"))
#' apply_encoding(training, recipe)
#' apply_encoding(data.frame(x = 100, group = "B"), recipe)
#' @seealso [apply_encoding()], [prepare_model_matrix()], [fit_imputation()],
#'   [center_scale()]
#' @export
fit_encoding <- function(data, covariates) {
  covariates <- validate_model_covariates(data, covariates)
  validate_model_vectors(data, covariates)
  validate_model_names(covariates)
  frame <- prepare_covariate_frame(data, covariates)
  variables <- stats::setNames(vector("list", length(covariates)), covariates)
  if (!length(covariates)) {
    return(list(version = 1L, variables = variables, columns = character(0)))
  }

  level_counts <- vapply(frame, function(column) {
    if (is.factor(column)) {
      if (anyNA(levels(column))) {
        stop("Explicit NA factor levels are unsupported; use missing values")
      }
      nlevels(column)
    } else if (is.logical(column)) {
      2L
    } else {
      1L
    }
  }, integer(1))
  size <- max(level_counts)
  # Probe every level without retaining training rows. Let model.matrix()
  # resolve the original contrast attributes and no-intercept dummy coding.
  probe <- lapply(frame, function(column) {
    if (is.factor(column)) {
      result <- factor(rep(levels(column), length.out = size),
        levels = levels(column), ordered = is.ordered(column)
      )
      attr(result, "contrasts") <- attr(column, "contrasts", exact = TRUE)
      result
    } else if (is.logical(column)) {
      result <- rep(c(FALSE, TRUE), length.out = size)
      attr(result, "contrasts") <- attr(column, "contrasts", exact = TRUE)
      result
    } else {
      rep(0, size)
    }
  })
  probe <- as.data.frame(probe, check.names = FALSE)
  design <- prepare_model_matrix(probe, covariates)
  columns <- colnames(design)
  if (!valid_encoding_names(columns)) {
    stop("Encoding creates ambiguous output column names; rename covariates or levels")
  }
  assignment <- attr(design, "assign")
  for (i in seq_along(covariates)) {
    variable <- covariates[i]
    column <- frame[[variable]]
    selected <- which(assignment == i)
    kind <- if (is.factor(column)) {
      "categorical"
    } else if (is.logical(column)) {
      "logical"
    } else {
      "numeric"
    }
    coding <- NULL
    if (kind != "numeric") {
      coding <- design[seq_len(level_counts[i]), selected, drop = FALSE]
      rownames(coding) <- if (kind == "logical") c("FALSE", "TRUE") else levels(column)
    }
    variables[[variable]] <- list(
      kind = kind, columns = columns[selected], coding = coding
    )
  }
  recipe <- list(version = 1L, variables = variables, columns = columns)
  validate_encoding_recipe(recipe)
  recipe
}

#' Apply saved covariate encoding
#'
#' Builds a matrix using a recipe from [fit_encoding()], without learning
#' levels or reevaluating contrasts from new data. Output columns always follow
#' the training recipe, even for empty data or a single observed category.
#'
#' Numeric inputs must remain real numeric vectors without infinite values;
#' logical inputs must remain logical. Categorical inputs may be character or
#' factor vectors. Factor level order and unused declared levels on new data
#' do not affect coding. An observed nonmissing category absent from the recipe
#' raises an error. Missing categories produce `NA` in their whole coding block;
#' numeric missing values pass through. Rows are never omitted.
#'
#' @param data A `data.frame` containing the recipe's covariates. Other columns
#'   are ignored. Names must be unique, nonmissing, and nonempty.
#' @param recipe An unmodified version-1 recipe returned by [fit_encoding()].
#'
#' @return A plain numeric matrix with the saved column names and order and
#'   the input row names and order. It does not include `model.matrix()`'s
#'   `assign` or `contrasts` attributes. No intercept, imputation, scaling,
#'   interaction terms, rank checks, or automatic cross-validation integration
#'   are added. An empty recipe returns a matrix with zero columns.
#' @examples
#' recipe <- fit_encoding(data.frame(group = c("A", "B")), "group")
#' apply_encoding(data.frame(group = c("B", NA)), recipe)
#' @seealso [fit_encoding()], [apply_imputation()], [apply_center_scale()]
#' @export
apply_encoding <- function(data, recipe) {
  validate_encoding_recipe(recipe)
  covariates <- validate_model_covariates(data, names(recipe$variables))
  validate_model_vectors(data, covariates)
  result <- matrix(NA_real_, nrow(data), length(recipe$columns),
    dimnames = list(rownames(data), recipe$columns)
  )
  for (variable in covariates) {
    specification <- recipe$variables[[variable]]
    column <- data[[variable]]
    if (specification$kind == "numeric") {
      if (!is_numeric_vector(column) || any(is.infinite(column))) {
        stop(sprintf("Covariate '%s' must be real numeric without infinite values", variable))
      }
      result[, specification$columns] <- as.numeric(column)
    } else {
      valid_type <- if (specification$kind == "logical") {
        is.logical(column)
      } else {
        is.factor(column) || is.character(column)
      }
      if (!valid_type) {
        stop(sprintf("Covariate '%s' must remain %s", variable, specification$kind))
      }
      values <- as.character(column)
      index <- match(values, rownames(specification$coding))
      unknown <- !is.na(values) & is.na(index)
      if (any(unknown)) {
        stop(sprintf(
          "Unseen levels for covariate '%s': %s", variable,
          paste(unique(values[unknown]), collapse = ", ")
        ))
      }
      result[, specification$columns] <- specification$coding[index, , drop = FALSE]
    }
  }
  result
}

valid_encoding_names <- function(x) {
  is.character(x) && is.null(dim(x)) && !anyNA(x) &&
    !any(x == "") && !anyDuplicated(x)
}

encoding_list_has <- function(x, required) {
  is.list(x) && !is.object(x) && is.null(dim(x)) &&
    valid_encoding_names(names(x)) && all(required %in% names(x))
}

validate_encoding_recipe <- function(recipe) {
  invalid <- function() stop("Invalid encoding recipe; use the result of fit_encoding()")
  if (!encoding_list_has(recipe, c("version", "variables", "columns")) ||
    !identical(recipe$version, 1L) || !valid_encoding_names(recipe$columns)) {
    invalid()
  }
  variables <- recipe$variables
  if (!is.list(variables) || is.object(variables) || !is.null(dim(variables)) ||
    (length(variables) && !valid_encoding_names(names(variables)))) {
    invalid()
  }
  validate_model_names(names(variables))
  columns <- character(0)
  for (specification in variables) {
    if (!encoding_list_has(specification, c("kind", "columns", "coding")) ||
      !is.character(specification$kind) || length(specification$kind) != 1L ||
      is.na(specification$kind) || !specification$kind %in% c("numeric", "logical", "categorical") ||
      !valid_encoding_names(specification$columns) || !length(specification$columns)) {
      invalid()
    }
    coding <- specification$coding
    if (specification$kind == "numeric") {
      if (length(specification$columns) != 1L || !is.null(coding)) invalid()
    } else {
      if (!is.matrix(coding) || !is.numeric(coding) || is.complex(coding) ||
        any(!is.finite(coding)) || nrow(coding) < 2L ||
        !identical(colnames(coding), specification$columns) ||
        is.null(rownames(coding)) || anyNA(rownames(coding)) ||
        anyDuplicated(rownames(coding))) {
        invalid()
      }
      if (specification$kind == "logical" &&
        !identical(rownames(coding), c("FALSE", "TRUE"))) {
        invalid()
      }
    }
    columns <- c(columns, specification$columns)
  }
  if (!identical(columns, recipe$columns)) invalid()
  invisible(TRUE)
}
