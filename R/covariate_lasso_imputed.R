#' Screen covariates with training-fold imputation and optional encoding
#'
#' Fits mean, median, or nearest-neighbor imputation on each training fold, fits a
#' Gaussian LASSO/elastic-net path, and scores its held-out predictions. Uses
#' [glmnet::glmnet()] with an intercept and training-specific standardization.
#' An explicit penalty grid is required; no grid is estimated from validation
#' rows. This is an experimental API.
#' Set `encode = TRUE` to fit additive categorical encoding within each
#' training fold as well as numeric imputation.
#'
#' Only rows with missing responses are excluded. Missing numeric predictors
#' (`NA` or `NaN`) are filled using that fold's training replacements or donors. Each
#' training fold must have an observed value for every predictor, a varying
#' response, and at least one varying predictor after imputation. For `"knn"`,
#' every missing training or held-out entry also needs comparable training
#' donors; otherwise an error names the affected fold and target. Infinite
#' values on retained rows raise errors. Entirely missing held-out predictors
#' are allowed when they can be imputed. Supply raw predictors:
#' preprocessing performed before this call cannot be undone or refitted by it.
#'
#' Selection minimizes mean squared error across all retained held-out rows,
#' giving each observation equal weight. Exact ties favor the largest penalty.
#' After selection, imputation and the model path are refitted on all retained
#' development rows. The returned model is not a cross-validation prediction.
#' The minimum tuning error is not an unbiased estimate of future performance;
#' use an independent test set or outer resampling for that purpose.
#'
#' Supplying `id` keeps a subject's retained observations in one fold; it does
#' not fit a mixed model or give subjects equal scoring weight. Default random
#' folds balance subjects (or rows without `id`). Set a seed for reproducible
#' random folds. Explicit `foldid` does not generate random folds.
#' One-standard-error selection is not implemented here.
#' [screen_covariates_lasso()] keeps its existing
#' complete-case behavior.
#'
#' With `method = "knn"`, numeric candidates are imputation targets and all
#' candidates are distance predictors; the current target is excluded from its own distance.
#' Neither the response nor `id` enters the donor model. [fit_knn_imputation()]
#' saves training donors and numeric ranges, and [apply_knn_imputation()] uses
#' bounded, available-pair weighted Gower distances. It averages up to `k`
#' comparable donor values, breaking exact distance ties in original training
#' row order. Each target uses the original recipient values, without cascading
#' imputations. No held-out row becomes a donor or changes the saved scales.
#' There is no fallback imputation. `k` and `weights` are fixed within the call;
#' they are not tuned. Saved fold and final models retain selected training
#' predictor values. See the imputer's help for full distance and weight rules.
#'
#' With `encode = TRUE`, numeric, character, factor, and logical candidates
#' are accepted. Imputation fills numeric candidates only, then [fit_encoding()]
#' learns the training design and [apply_encoding()] reuses it for held-out
#' rows. Categorical values must be observed. Unknown held-out categories raise
#' a fold-context error; there is no pooling, category imputation, or silent
#' row removal. Characters learn levels from training rows; factors retain
#' declared levels, which must come from a prespecified schema or training data.
#' Unused declared levels are allowed but their effects cannot be estimated
#' from training observations that do not contain them.
#'
#' Encoding uses the additive, no-intercept design of [fit_encoding()]: the
#' first categorical term has full indicators and subsequent terms use the
#' contrasts active during fitting. The Gaussian model supplies an intercept.
#' Penalties apply to individual standardized design columns, not whole
#' categorical variables. Selection depends on coding; redundant indicator
#' coefficients may be nonunique. `selected` maps nonzero columns back to raw
#' candidates and is not a grouped test or post-selection inference. Each
#' training design needs at least two columns and one varying column.
#'
#' @param data A `data.frame` with unique, nonmissing, nonempty column names.
#' @param response Name of a real numeric response column.
#' @param covariates Unique predictor column names, matched literally. With
#'   `encode = FALSE`, at least two real numeric columns are required. With
#'   `encode = TRUE`, at least one numeric, character, factor, or logical
#'   candidate is required, producing at least two design columns. Exclude
#'   the response and subject identifier.
#' @param lambda A prespecified numeric vector of at least two distinct, finite,
#'   strictly positive penalties. Values are sorted in decreasing order. Choose
#'   the grid independently of held-out outcomes and preprocessing statistics.
#'   A backend path that does not cover the full grid raises an error.
#' @param method Training imputation: `"mean"` (default), `"median"`, or `"knn"`.
#' @param alpha Finite number in `[0, 1]`: `1` is LASSO (default), `0` is ridge,
#'   and intermediate values use an elastic-net penalty. Ridge generally does
#'   not select a sparse subset.
#' @param id Optional subject identifier column, distinct from the response
#'   and predictors. Must be nonmissing on retained rows.
#' @param nfolds Number of random folds, an integer of at least three and at
#'   most the number of retained subjects or rows. Ignored with `foldid`.
#' @param foldid Optional positive integer labels, one per original data row.
#'   Labels are subset to retained rows and renumbered in sorted order. At least
#'   three nonempty folds must remain; a retained subject cannot span folds.
#' @param k Positive integer neighbor count for `method = "knn"`, default five.
#'   Ignored for mean/median imputation. Must be at most `.Machine$integer.max`.
#' @param weights Optional named nonnegative finite distance weights for the
#'   selected covariates, used only with `method = "knn"`. Omitted weights are
#'   one; zero weights exclude distance predictors. Each target needs another
#'   positive-weight predictor. These are not observation or scoring weights.
#' @param encode Logical, default `FALSE` for the existing numeric-only
#'   workflow. `TRUE` fits and saves categorical encoding within each training
#'   fold and on the final development data. Mean/median allow categorical-only
#'   designs (an empty numeric replacement table); kNN needs a numeric target.
#'
#' @return An object of class `pharma_lasso_imputed` (also a list) containing:
#' \describe{
#'   \item{selected}{Raw covariates with any nonzero final-model design column
#'     at `lambda.min`, in input order.}
#'   \item{lambda.min}{The penalty with minimum held-out mean squared error.}
#'   \item{alpha}{The supplied mixing parameter, retained for reproducibility.}
#'   \item{method}{The chosen imputation method.}
#'   \item{covariates}{All candidate names in the order required for prediction.}
#'   \item{cv}{Data frame with decreasing `lambda` and observation-weighted `mse`.}
#'   \item{predictions}{Held-out prediction matrix, with original row names/order
#'     and columns corresponding to rows of `cv`. Excluded response rows are `NA`.}
#'   \item{foldid}{Normalized fold labels in original row order; `NA` for exclusions.}
#'   \item{fold_imputation}{Named list by normalized fold: replacement tables
#'     for mean/median, or saved donor models for `"knn"`.}
#'   \item{fit}{The final `glmnet` path fitted on all retained development rows.}
#'   \item{imputation}{The final replacement table for [apply_imputation()], or
#'     the final donor model for [apply_knn_imputation()] when `method = "knn"`.}
#' }
#' With `encode = TRUE`, three additional entries are returned: `encoding`
#' (the final recipe), `fold_encoding` (recipes named by normalized fold),
#' and `selected_columns` (nonzero final design-column names at `lambda.min`).
#' These entries are absent for default numeric-only calls.
#' Save the result with [base::saveRDS()]. Use [predict_lasso_imputed()] to apply
#' its final imputer, restore predictor order, and predict at `lambda.min` or
#' other penalties from the fitted grid. The model already includes its training
#' standardization; do not impute or rescale new data before this helper.
#' Use `summary(result)` for selected-penalty coefficients, tuning error,
#' and analysis-row/fold counts; `coef(summary(result))` extracts the estimate
#' table. Use `coef(result)` for saved coefficients and `predict(result,
#' newdata)` for raw-row predictions, optionally at requested fitted penalties.
#' See [coef.pharma_lasso_imputed()] for the standard model methods and
#' [summary.pharma_lasso_imputed()] for interpretation and older
#' saved-list migration.
#' @examples
#' block <- data.frame(
#'   x1 = c(-1, -1, 1, 1, NA, NA), x2 = c(-1, 1, -1, 1, -1, 1),
#'   y = c(-2, -2, 2, 2, 0, 0)
#' )
#' training <- block[rep(seq_len(6), 3), ]
#' result <- screen_covariates_lasso_imputed(
#'   training, "y", c("x1", "x2"),
#'   lambda = c(2, 1, 0.5),
#'   foldid = rep(1:3, each = 6)
#' )
#' result$cv # MSE: 8/3, 1, 1/4
#' result$selected # "x1"
#' summary(result)
#' coef(summary(result))
#' new_data <- data.frame(x1 = c(NA, 1), x2 = c(1, -1))
#' predict_lasso_imputed(result, new_data)
#' neighbors <- screen_covariates_lasso_imputed(
#'   training, "y", c("x1", "x2"),
#'   lambda = c(2, 1, 0.5),
#'   method = "knn", k = 2, foldid = rep(1:3, each = 6)
#' )
#' neighbors$cv # the two nearest donor values average to zero in this example
#' predict_lasso_imputed(neighbors, new_data)
#' training$group <- ifelse(training$x2 == -1, "A", "B")
#' mixed <- screen_covariates_lasso_imputed(
#'   training, "y", c("x1", "group"),
#'   lambda = c(2, 1, 0.5),
#'   encode = TRUE, foldid = rep(1:3, each = 6)
#' )
#' predict_lasso_imputed(mixed, data.frame(group = "B", x1 = NA_real_))
#' @seealso [predict_lasso_imputed()], [fit_imputation()],
#'   [fit_knn_imputation()], [fit_encoding()], [screen_covariates_lasso()]
#' @export
screen_covariates_lasso_imputed <- function(data, response, covariates, lambda,
                                            method = c("mean", "median", "knn"), alpha = 1,
                                            id = NULL, nfolds = 10L, foldid = NULL,
                                            k = 5L, weights = NULL, encode = FALSE) {
  method <- match.arg(method)
  if (!is.logical(encode) || length(encode) != 1L || is.na(encode) || !is.null(dim(encode))) {
    stop("`encode` must be TRUE or FALSE")
  }
  covariates <- validate_model_covariates(data, covariates)
  if (!is.character(response) || !is.null(dim(response)) || length(response) != 1L ||
    is.na(response) || !response %in% names(data)) {
    stop("`response` must name a real numeric column in `data`")
  }
  if (!encode && length(covariates) < 2L) {
    stop("Imputed LASSO screening requires at least two numeric covariates")
  }
  if (encode && !length(covariates)) {
    stop("Encoded screening requires at least one candidate covariate")
  }
  if (response %in% covariates) {
    stop("`response` cannot also be a candidate covariate")
  }
  if (!is.null(id)) {
    if (!is.character(id) || !is.null(dim(id)) || length(id) != 1L ||
      is.na(id) || !id %in% names(data)) {
      stop("`id` must name a subject identifier column in `data`")
    }
    if (id %in% c(response, covariates)) {
      stop("`id` must be distinct from the response and covariates")
    }
  }
  if (!is_numeric_vector(alpha) || length(alpha) != 1L ||
    !is.finite(alpha) || alpha < 0 || alpha > 1) {
    stop("`alpha` must be a finite number between 0 and 1")
  }
  if (!is_numeric_vector(lambda) || length(lambda) < 2L ||
    any(!is.finite(lambda)) || any(lambda <= 0) || anyDuplicated(lambda)) {
    stop("`lambda` must contain at least two distinct finite positive penalties")
  }
  lambda <- sort(unname(lambda), decreasing = TRUE)
  if (method == "knn") {
    validate_knn_k(k)
    weights <- prepare_imputation_weights(weights, covariates)
  }
  vars <- c(response, covariates)
  if (encode) {
    validate_model_vectors(data, covariates)
    validate_model_names(covariates)
  }
  if (!is_numeric_vector(data[[response]]) ||
    (!encode && !all(vapply(data[covariates], is_numeric_vector, logical(1))))) {
    stop("Response and covariate columns must be real numeric vectors")
  }
  keep <- !is.na(data[[response]])
  retained <- data[keep, vars, drop = FALSE]
  if (nrow(retained) < 3L) {
    stop("At least three observed-response rows are required")
  }
  if (any(vapply(retained, function(column) {
    is_numeric_vector(column) && any(is.infinite(column))
  }, logical(1)))) {
    stop("Response and covariates must not contain infinite values on retained rows")
  }
  subjects <- if (is.null(id)) NULL else data[[id]]
  folds <- make_lasso_folds(keep, subjects, nfolds, foldid)
  labels <- sort(unique(folds))
  predictions <- matrix(NA_real_, nrow(retained), length(lambda))
  fold_imputation <- stats::setNames(vector("list", length(labels)), as.character(labels))
  fold_encoding <- fold_imputation
  for (fold in labels) {
    held_out <- folds == fold
    context <- sprintf("Training data excluding fold %s", fold)
    trained <- fit_imputed_lasso_path(
      retained[!held_out, , drop = FALSE], response, covariates,
      method, lambda, alpha, context, k, weights, encode
    )
    completed <- tryCatch(
      apply_lasso_design(
        retained[held_out, , drop = FALSE], trained$imputation,
        method, covariates, trained$encoding
      ),
      error = function(error) {
        stop(sprintf("Held-out data for fold %s: %s", fold, conditionMessage(error)), call. = FALSE)
      }
    )
    predicted <- stats::predict(trained$fit,
      newx = completed, s = lambda
    )
    if (any(!is.finite(predicted))) {
      stop(sprintf("Nonfinite held-out predictions for fold %s", fold))
    }
    predictions[held_out, ] <- predicted
    fold_imputation[[as.character(fold)]] <- trained$imputation
    if (encode) fold_encoding[[as.character(fold)]] <- trained$encoding
  }
  mse <- colMeans((predictions - retained[[response]])^2)
  if (any(!is.finite(mse))) {
    stop("Held-out squared errors must be finite; review the data scale")
  }
  best <- which.min(mse)
  final <- fit_imputed_lasso_path(
    retained, response, covariates, method, lambda, alpha, "Final training data", k, weights, encode
  )
  coefficients <- as.matrix(stats::coef(final$fit, s = lambda[best]))[-1L, 1L]
  aligned_predictions <- matrix(NA_real_, nrow(data), length(lambda),
    dimnames = list(rownames(data), paste0("lambda_", seq_along(lambda)))
  )
  aligned_predictions[keep, ] <- predictions
  aligned_folds <- rep(NA_integer_, nrow(data))
  aligned_folds[keep] <- folds
  selected_columns <- names(coefficients)[coefficients != 0]
  selected <- if (encode) {
    covariates[vapply(final$encoding$variables, function(variable) {
      any(variable$columns %in% selected_columns)
    }, logical(1))]
  } else {
    covariates[coefficients != 0]
  }
  result <- list(
    selected = selected, lambda.min = lambda[best], alpha = unname(alpha),
    method = method, covariates = covariates,
    cv = data.frame(lambda = lambda, mse = unname(mse)),
    predictions = aligned_predictions, foldid = aligned_folds,
    fold_imputation = fold_imputation, fit = final$fit,
    imputation = final$imputation
  )
  if (encode) {
    result$encoding <- final$encoding
    result$fold_encoding <- fold_encoding
    result$selected_columns <- selected_columns
  }
  structure(result, class = c("pharma_lasso_imputed", "list"))
}

fit_imputed_lasso_path <- function(data, response, covariates, method,
                                   lambda, alpha, context, k = 5L, weights = NULL,
                                   encode = FALSE) {
  tryCatch(
    {
      if (length(unique(data[[response]])) < 2L) {
        stop("constant response")
      }
      numeric_vars <- covariates[vapply(data[covariates], is_numeric_vector, logical(1))]
      params <- if (method == "knn") {
        if (!length(numeric_vars)) stop("kNN imputation requires at least one numeric candidate")
        fit_knn_imputation(data, numeric_vars, covariates, k, weights)
      } else {
        fit_imputation(data, numeric_vars, method)
      }
      completed <- apply_lasso_imputation(data, params, method)
      encoding <- if (encode) fit_encoding(completed, covariates) else NULL
      x <- lasso_design(completed, covariates, encoding)
      if (ncol(x) < 2L) stop("The fitted design needs at least two columns")
      varying <- vapply(seq_len(ncol(x)), function(column) {
        length(unique(x[, column])) > 1L
      }, logical(1))
      if (!any(varying)) {
        stop("no varying covariates after imputation")
      }
      fit <- glmnet::glmnet(x, data[[response]],
        family = "gaussian", alpha = alpha, lambda = lambda,
        intercept = TRUE, standardize = TRUE
      )
      # glmnet can round supplied penalties when scaling and unscaling y.
      if (!isTRUE(all.equal(unname(fit$lambda), lambda, tolerance = 1e-12)) ||
        any(!is.finite(as.matrix(stats::coef(fit))))) {
        stop("glmnet did not produce a complete finite path for the requested lambda grid")
      }
      list(fit = fit, imputation = params, encoding = encoding)
    },
    error = function(error) {
      stop(context, ": ", conditionMessage(error), call. = FALSE)
    }
  )
}

apply_lasso_design <- function(data, params, method, covariates, encoding = NULL) {
  completed <- apply_lasso_imputation(data, params, method)
  lasso_design(completed, covariates, encoding)
}

lasso_design <- function(data, covariates, encoding = NULL) {
  if (is.null(encoding)) {
    return(as.matrix(data[covariates]))
  }
  design <- apply_encoding(data, encoding)
  if (any(!is.finite(design))) {
    stop("Encoded predictors must be finite; categorical values cannot be missing")
  }
  design
}

apply_lasso_imputation <- function(data, params, method) {
  if (method != "knn") {
    return(apply_imputation(data, params))
  }
  # The standalone imputer warns and leaves incomparable entries missing.
  # Screening requires a completed matrix; propagate a contextual error instead.
  withCallingHandlers(
    apply_knn_imputation(data, params),
    warning = function(warning) stop(conditionMessage(warning), call. = FALSE)
  )
}
