#' Fit a reusable nearest-neighbor imputation model
#'
#' Saves training donors and Gower distance scales for numeric target columns.
#' Apply the model with [apply_knn_imputation()] without learning from new rows.
#' Split data before fitting; fit a separate model within each training fold.
#'
#' Predictors must be explicitly selected. Exclude outcomes, identifiers, and
#' information unavailable at prediction time. The current target is always
#' excluded from its own distance calculation. Numeric and ordered predictors
#' use ranges observed across all supplied training rows; ordered factors use
#' their declared level order. Nominal predictors use match/mismatch distances,
#' and logical predictors are symmetric (two `FALSE` values match).
#'
#' Numeric contributions are absolute differences divided by the saved range,
#' capped at one for new values outside that range. Constant training predictors
#' contribute zero when jointly observed. Missing predictor pairs are omitted;
#' distance is the weighted mean of remaining contributions. All-missing
#' training predictors cannot contribute. Unspecified weights are one; zero
#' weights exclude a predictor before checking its values or saving its data.
#'
#' For each missing target, use up to `k` comparable training rows with observed
#' target values, ordered by distance and then training row order. Their
#' unweighted target mean is the replacement. Rows with no comparable donors
#' remain missing with a warning. This is single imputation and does not
#' quantify missing-data uncertainty. For numeric screening within training
#' folds, use [screen_covariates_lasso_imputed()] with `method = "knn"`.
#' [impute_ml()] retains its existing behavior.
#'
#' @param data Training data frame with unique, nonmissing, nonempty names.
#' @param vars Nonempty character vector of unique numeric target names. Every
#'   target needs at least one observed training value. Names match literally.
#' @param predictors Nonempty character vector of unique predictor names.
#'   Positive-weight predictors must be numeric, character, logical, or factors.
#'   Each target needs at least one other positive-weight predictor.
#' @param k Positive integer, at most `.Machine$integer.max`; defaults to five.
#' @param weights Optional named vector of finite nonnegative predictor weights.
#'   Names must be selected predictors; omitted weights default to one.
#'
#' @return A plain, versioned list for [apply_knn_imputation()], serializable
#'   with [base::saveRDS()]. It retains selected training target values and
#'   transformed predictor values, together with names, weights, scales, and
#'   ordered levels. It contains no unrelated columns. Treat this saved model
#'   as training data; its internal structure is not an editing interface.
#' @examples
#' training <- data.frame(
#'   value = c(10, 20), x = c(0, 10),
#'   group = c("a", "b")
#' )
#' model <- fit_knn_imputation(training, "value", c("x", "group"), k = 1)
#' apply_knn_imputation(data.frame(value = NA_real_, x = 2, group = "a"), model)
#' @seealso [apply_knn_imputation()], [fit_imputation()], [impute_ml()]
#' @export
fit_knn_imputation <- function(data, vars, predictors, k = 5L, weights = NULL) {
  validate_data_frame_names(data)
  validate_knn_names(vars, "vars")
  validate_knn_names(predictors, "predictors")
  vars <- unname(vars)
  predictors <- unname(predictors)
  validate_preprocessing_vars(data, vars)
  if (!all(predictors %in% names(data))) {
    stop("All `predictors` must be columns in `data`")
  }
  validate_knn_k(k)
  weights <- prepare_imputation_weights(weights, predictors)
  predictors <- predictors[weights > 0]
  weights <- weights[predictors]
  validate_preprocessing_vars(data, predictors, numeric_only = FALSE)
  for (variable in vars) {
    if (all(is.na(data[[variable]]))) {
      stop(sprintf("Target '%s' needs an observed training value", variable))
    }
    if (length(setdiff(predictors, variable)) == 0L) {
      stop(sprintf("Target '%s' needs another positive-weight predictor", variable))
    }
  }
  schema <- lapply(data[predictors], fit_knn_predictor)
  donor_predictors <- Map(prepare_knn_predictor, data[predictors], schema)
  list(
    version = 1L, vars = vars, predictors = predictors, k = as.integer(k),
    weights = weights, schema = schema, donor_predictors = donor_predictors,
    donor_targets = as.data.frame(data[vars])
  )
}

#' Impute new numeric data from saved training neighbors
#'
#' Uses only the donors, ranges, and weights saved by [fit_knn_imputation()].
#' New rows never become donors or affect each other's distances. Every target
#' uses the original input predictor values, so target order does not cause
#' cascading imputations. Observed targets remain unchanged.
#'
#' Numeric predictors must remain numeric and logical predictors logical.
#' Nominal predictors accept character or unordered factors, including unseen
#' values, which mismatch all different donor values. Ordered predictors accept
#' factors or character values from the saved levels; the training order always
#' applies, and unseen observed levels raise an error. Explicit `NA` factor
#' levels are unsupported; ordinary missing values are allowed. Selected numeric
#' columns must be finite or missing. Zero-weight predictors need not be present.
#'
#' @param data Data frame containing the targets and positive-weight predictors.
#'   Empty data and entirely missing new target columns are allowed.
#' @param model Unmodified model returned by [fit_knn_imputation()].
#' @return A data frame with selected missing entries filled when comparable
#'   donors exist. Row order, row names, column order, unselected columns, and
#'   observed values are preserved. Integer targets may become double. Neither
#'   the input data nor the model is modified.
#' @examples
#' model <- fit_knn_imputation(data.frame(y = c(2, 5), x = c(0, 10)),
#'   "y", "x",
#'   k = 2
#' )
#' apply_knn_imputation(data.frame(y = c(NA, 100), x = c(2, 3)), model)
#' @seealso [fit_knn_imputation()], [apply_imputation()]
#' @export
apply_knn_imputation <- function(data, model) {
  validate_knn_model(model)
  validate_preprocessing_vars(data, model$vars)
  validate_preprocessing_vars(data, model$predictors, numeric_only = FALSE)
  prepared <- Map(prepare_knn_predictor, data[model$predictors], model$schema)
  n <- nrow(model$donor_targets)
  for (variable in model$vars) {
    missing <- which(is.na(data[[variable]]))
    predictors <- setdiff(model$predictors, variable)
    donors <- which(!is.na(model$donor_targets[[variable]]))
    unavailable <- 0L
    for (row in missing) {
      # Append only this recipient to the frozen predictors; no new row is a donor.
      pairs <- Map(
        function(training, new) c(training, new[row]),
        model$donor_predictors[predictors], prepared[predictors]
      )
      distances <- gower_imputation_distances(
        pairs, donors, n + 1L, model$weights[predictors],
        max_contribution = 1
      )
      comparable <- which(!is.na(distances))
      if (length(comparable) == 0L) {
        unavailable <- unavailable + 1L
        next
      }
      nearest <- comparable[order(distances[comparable])]
      selected <- donors[utils::head(nearest, model$k)]
      data[[variable]][row] <- mean(model$donor_targets[[variable]][selected])
    }
    if (unavailable > 0L) {
      warning(sprintf(
        "Target '%s': %d missing value(s) have no comparable training donors",
        variable, unavailable
      ), call. = FALSE)
    }
  }
  data
}

validate_knn_names <- function(x, argument) {
  if (!is.character(x) || !is.null(dim(x)) || length(x) == 0L ||
    anyNA(x) || any(x == "") || anyDuplicated(x)) {
    stop(sprintf("`%s` must be a nonempty vector of unique column names", argument))
  }
}

validate_knn_k <- function(k) {
  if (!is_numeric_vector(k) || length(k) != 1L || !is.finite(k) ||
    k < 1 || k > .Machine$integer.max || k != floor(k)) {
    stop("`k` must be a positive integer at most .Machine$integer.max")
  }
}

fit_knn_predictor <- function(column) {
  if (is.factor(column) && anyNA(levels(column))) {
    stop("Explicit NA factor levels are unsupported")
  }
  kind <- if (is.ordered(column)) {
    "ordered"
  } else if (is.numeric(column)) {
    "numeric"
  } else if (is.logical(column)) "logical" else "nominal"
  schema <- list(kind = kind, levels = NULL, offset = 0, span = 0, divisor = 1)
  if (kind == "ordered") schema$levels <- levels(column)
  if (kind %in% c("numeric", "ordered")) {
    observed <- as.numeric(column[!is.na(column)])
    if (length(observed)) {
      limits <- range(observed)
      if (!is.finite(limits[2L] - limits[1L])) {
        schema$divisor <- 2
        limits <- limits / 2
      }
      schema$offset <- limits[1L]
      schema$span <- limits[2L] - limits[1L]
    }
  }
  schema
}

prepare_knn_predictor <- function(column, schema) {
  if (is.factor(column) && anyNA(levels(column))) {
    stop("Explicit NA factor levels are unsupported")
  }
  kind <- schema$kind
  if (kind == "numeric" && !is_numeric_vector(column)) {
    stop("A numeric training predictor must remain numeric")
  }
  if (kind == "logical" && !is.logical(column)) {
    stop("A logical training predictor must remain logical")
  }
  if (kind == "nominal" && !(is.character(column) ||
    (is.factor(column) && !is.ordered(column)))) {
    stop("A nominal training predictor needs character or unordered factor values")
  }
  if (kind == "ordered") {
    if (!(is.character(column) || is.factor(column))) {
      stop("An ordered training predictor needs factor or character values")
    }
    codes <- match(as.character(column), schema$levels)
    if (any(!is.na(column) & is.na(codes))) {
      stop("Unseen observed level in an ordered training predictor")
    }
    column <- codes
  }
  if (kind %in% c("numeric", "ordered")) {
    column <- as.numeric(column)
    if (schema$span == 0) {
      column[!is.na(column)] <- 0
      return(column)
    }
    # Very distant finite new values may normalize to Inf; their bounded
    # contribution is still one against every finite training donor.
    return((column / schema$divisor - schema$offset) / schema$span)
  }
  as.character(column)
}
