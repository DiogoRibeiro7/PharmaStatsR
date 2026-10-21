#' Impute missing values using the mean
#'
#' Replaces missing values (`NA` or `NaN`) in specified numeric columns with
#' the observed column mean. Infinite values and nonnumeric targets are
#' rejected. Constant columns with observed values can be imputed.
#' A non-finite direct mean is recomputed in normalized units to avoid
#' intermediate overflow for finite observations. Finite direct results are
#' retained; this fallback does not recover precision already lost in inputs.
#'
#' @param data A `data.frame` containing variables to impute.
#' @param vars Character vector of unique numeric column names to impute.
#'
#' @return Data frame with imputed values. Columns consisting entirely of
#'   `NA` values are left unchanged and trigger a warning.
#' @examples
#' df <- data.frame(a = c(1, NA, 3), b = c(NA, NA, 2))
#' impute_mean(df, c("a", "b"))
#' @seealso [fit_imputation()] and [apply_imputation()] for training-fitted
#'   replacements reused on new data.
#' @export
impute_mean <- function(data, vars) {
  impute_location(data, vars, preprocessing_mean)
}

#' Impute missing values using the median
#'
#' Replaces missing values (`NA` or `NaN`) in specified numeric columns with
#' the observed column median. Infinite values and nonnumeric targets are
#' rejected. Constant columns with observed values can be imputed.
#'
#' @param data A `data.frame` containing variables to impute.
#' @param vars Character vector of unique numeric column names to impute.
#'
#' @return Data frame with imputed values. Columns consisting entirely of
#'   `NA` values are left unchanged and trigger a warning.
#' @examples
#' df <- data.frame(a = c(1, NA, 3), b = c(NA, NA, 2))
#' impute_median(df, c("a", "b"))
#' @seealso [fit_imputation()] and [apply_imputation()] for training-fitted
#'   replacements reused on new data.
#' @export
impute_median <- function(data, vars) {
  impute_location(data, vars, stats::median)
}

impute_location <- function(data, vars, summary_function) {
  validate_preprocessing_vars(data, vars)
  if (nrow(data) == 0L) {
    return(data)
  }
  for (v in vars) {
    column <- data[[v]]
    if (all(is.na(column))) {
      warning(
        sprintf("Column '%s' contains only NA; no imputation performed", v)
      )
      next
    }
    value <- summary_function(column, na.rm = TRUE)
    if (!is.finite(value)) {
      stop(sprintf("Cannot compute a finite imputation value for '%s'", v))
    }
    data[[v]][is.na(column)] <- value
  }

  data
}

#' Impute missing values using a k-nearest-neighbors model
#'
#' Performs ML-style imputation by finding the `k` nearest observed rows for
#' each missing value and imputing from neighbors. Numeric targets are imputed
#' with the neighbor mean; non-numeric targets are imputed with the neighbor
#' mode. Targets may be numeric, logical, character, or factor vectors. Factor
#' levels and observed values are preserved; infinite values are rejected in
#' both targets and predictors used for imputation.
#'
#' By default, every other column is used as a predictor, including identifiers
#' and response columns if present. Supply `predictors` to restrict the columns
#' used for distance calculations while retaining the full input table. Only
#' selected targets are modified.
#'
#' The default Euclidean distance uses numeric predictors in their original
#' units and categorical predictors as factor codes. Missing predictor values
#' are filled internally with their encoded column mean (zero if entirely
#' missing). Scaled intermediate calculations limit overflow and underflow;
#' unrepresentable distances raise an error requesting rescaling.
#'
#' Gower distance averages available predictor contributions with equal weights
#' by default.
#' Numeric values and ordered-factor scores use observed-range scaling;
#' nominal factors, characters, and logicals use match/mismatch contributions.
#' Logical variables are symmetric binary: two `FALSE` values count as a match.
#' Constant numeric predictors contribute zero when both values are observed.
#' Ranges are estimated from all supplied rows for each target. Missing
#' predictor pairs are omitted from that pair's average, without mean filling.
#' Donors with no jointly observed predictors are excluded; if no donor remains,
#' the target value stays missing and a warning summarizes affected rows.
#'
#' Use `weights` to change predictors' relative influence. Weights multiply
#' squared differences for Euclidean distance and contributions for Gower
#' distance. Gower averages use only the weights of jointly observed predictors.
#' Zero-weight predictors are excluded before their types or values are checked.
#' Weights affect neighbor selection, not the mean or mode of selected donors.
#' Internally rescaling weights limits overflow without changing their relative
#' influence. Extreme relative scales can still lose precision.
#' Numeric donor means and Euclidean predictor-fill means are recomputed in
#' normalized units only if the direct result is non-finite. Ordinary finite
#' means are retained. This does not change selected donors or categorical modes.
#'
#' Equidistant donors are ordered by their original row order, and tied modes
#' use the first value among the selected neighbors. Targets are processed in
#' `vars` order, so earlier imputations can affect later targets when they are
#' also selected as predictors.
#'
#' @param data A `data.frame` containing variables to impute.
#' @param vars Character vector of unique column names to impute.
#' @param k Number of neighbors to use. Must be a finite, positive whole number.
#'   If larger than the number of comparable observed target values, all
#'   comparable donors are used.
#' @param predictors Optional character vector of unique predictor column names.
#'   `NULL` (the default) uses every column other than the current target. An
#'   explicit selection is shared across targets, with the current target
#'   removed automatically. Other targets are predictors only if selected.
#'   `character(0)` selects no predictors; targets needing imputation remain
#'   unchanged with a warning. Names are validated even if no values need
#'   imputation; predictor types and values are checked only when used.
#' @param distance Distance measure: `"euclidean"` (default) or `"gower"`.
#' @param weights Optional named numeric vector of finite, nonnegative predictor
#'   weights. Names must be unique and belong to `predictors` (or to `data` when
#'   `predictors = NULL`). Unspecified predictors receive weight 1; `NULL` or
#'   `numeric(0)` keeps equal weights. Names match literally, in any order.
#'   The current target is always excluded regardless of its weight.
#'   If no positive-weight predictors remain, targets needing imputation stay
#'   unchanged with a warning. Weights are validated even when no imputation is
#'   needed.
#'
#' @return Data frame with imputed values. Columns consisting entirely of
#'   `NA` values are left unchanged and trigger a warning.
#' @examples
#' df <- data.frame(
#'   a = c(1, NA, 3, 4),
#'   b = c(10, 11, 12, 13),
#'   grp = c("x", "x", "y", "y")
#' )
#' impute_ml(df, "a", k = 2)
#' # Keep the full table, using only b to find neighbors.
#' impute_ml(df, "a", k = 2, predictors = "b")
#' # Compare numeric and categorical predictors using Gower distance.
#' impute_ml(df, "a", k = 2, predictors = c("b", "grp"), distance = "gower")
#' # Give group matches twice the influence of the numeric predictor.
#' impute_ml(df, "a",
#'   k = 1, predictors = c("b", "grp"),
#'   distance = "gower", weights = c(grp = 2)
#' )
#' @seealso \code{\link[cluster]{daisy}} for the Gower dissimilarity definition.
#' @export
impute_ml <- function(data, vars, k = 5L, predictors = NULL,
                      distance = c("euclidean", "gower"), weights = NULL) {
  distance <- match.arg(distance)
  validate_preprocessing_vars(data, vars, numeric_only = FALSE)
  if (!is_numeric_vector(k) || length(k) != 1L || !is.finite(k) ||
    k < 1 || k != floor(k)) {
    stop("`k` must be a positive integer")
  }
  if (is.null(predictors)) {
    predictors <- names(data)
  } else {
    if (!is.character(predictors) || !is.null(dim(predictors)) ||
      anyNA(predictors) || anyDuplicated(predictors)) {
      stop("`predictors` must be a character vector of unique column names")
    }
    if (!all(predictors %in% names(data))) {
      missing <- setdiff(predictors, names(data))
      stop(sprintf("Predictors not found: %s", paste(missing, collapse = ", ")))
    }
  }

  weights <- prepare_imputation_weights(weights, predictors)

  mode_value <- function(x) {
    x <- x[!is.na(x)]
    if (length(x) == 0) {
      return(NA)
    }
    ux <- unique(x)
    ux[which.max(tabulate(match(x, ux)))]
  }

  for (target in vars) {
    y <- data[[target]]
    miss_idx <- which(is.na(y))
    if (length(miss_idx) == 0) {
      next
    }
    if (all(is.na(y))) {
      warning(
        sprintf("Column '%s' contains only NA; no imputation performed", target)
      )
      next
    }

    pred_cols <- setdiff(predictors[weights > 0], target)
    if (length(pred_cols) == 0) {
      warning(
        sprintf(
          "No predictor columns available for '%s'; no imputation performed",
          target
        )
      )
      next
    }
    validate_preprocessing_vars(data, pred_cols, numeric_only = FALSE)
    pred_weights <- unname(weights[pred_cols])

    if (distance == "gower") {
      predictor_data <- prepare_gower_predictors(data[pred_cols])
    } else {
      predictor_data <- prepare_euclidean_predictors(data[pred_cols])
    }

    obs_idx <- which(!is.na(y))
    unresolved <- 0L
    for (i in miss_idx) {
      if (distance == "gower") {
        dists <- gower_imputation_distances(
          predictor_data, obs_idx, i, pred_weights
        )
      } else {
        deltas <- sweep(
          predictor_data[obs_idx, , drop = FALSE], 2, predictor_data[i, ], "-"
        )
        dists <- imputation_distances(deltas, target, pred_weights)
      }
      available <- which(!is.na(dists))
      if (length(available) == 0L) {
        unresolved <- unresolved + 1L
        next
      }
      nearest <- available[order(dists[available])]
      nn <- obs_idx[nearest[seq_len(min(k, length(nearest)))]]
      neighbors <- y[nn]

      if (is.numeric(y)) {
        data[[target]][i] <- preprocessing_mean(neighbors, na.rm = TRUE)
      } else {
        data[[target]][i] <- mode_value(neighbors)
      }
    }
    if (unresolved > 0L) {
      warning(sprintf(
        "No comparable donors for '%s' in %d row(s); values left unchanged",
        target, unresolved
      ))
    }
  }

  data
}

prepare_euclidean_predictors <- function(data) {
  encode_predictor <- function(x) {
    if (is.numeric(x) || is.logical(x)) {
      return(as.numeric(x))
    }
    as.numeric(as.factor(x))
  }
  xmat <- sapply(data, encode_predictor)
  if (is.vector(xmat)) {
    xmat <- matrix(xmat, ncol = 1)
  }
  xmat <- as.matrix(xmat)
  for (j in seq_len(ncol(xmat))) {
    column <- xmat[, j]
    value <- preprocessing_mean(column, na.rm = TRUE)
    if (is.na(value)) {
      value <- 0
    }
    column[is.na(column)] <- value
    xmat[, j] <- column
  }
  xmat
}

imputation_distances <- function(deltas, target,
                                 weights = rep(1, ncol(deltas))) {
  error_message <- sprintf(
    "Distances for '%s' cannot be represented; rescale numeric predictors",
    target
  )
  if (any(!is.finite(deltas))) {
    stop(error_message)
  }
  # Normalize square roots first to preserve tiny positive relative weights.
  roots <- sqrt(weights)
  deltas <- sweep(deltas, 2L, roots / max(roots), "*")
  # Normalize each row before squaring to avoid overflow and underflow.
  row_scale <- apply(abs(deltas), 1L, max)
  denominator <- ifelse(row_scale == 0, 1, row_scale)
  normalized <- sweep(deltas, 1L, denominator, "/")
  distances <- row_scale * sqrt(rowSums(normalized^2))
  if (any(!is.finite(distances))) {
    stop(error_message)
  }
  distances
}
