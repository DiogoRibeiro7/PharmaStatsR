#' Screen numeric covariates with training-fold imputation
#'
#' Fits mean or median imputation separately on each training fold, fits a
#' Gaussian LASSO/elastic-net path, and scores its held-out predictions. Uses
#' [glmnet::glmnet()] with an intercept and training-specific standardization.
#' An explicit penalty grid is required; no grid is estimated from validation
#' rows. This is an experimental API.
#'
#' Only rows with missing responses are excluded. Missing numeric predictors
#' (`NA` or `NaN`) are filled using that fold's training replacements. Each
#' training fold must have an observed value for every predictor, a varying
#' response, and at least one varying predictor after imputation. Infinite
#' values on retained rows raise errors. Entirely missing held-out predictors
#' are allowed. Supply raw numeric predictors: preprocessing performed before
#' this call cannot be undone or refitted by it.
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
#' random folds. Explicit `foldid` does not generate random folds. Categorical
#' encoding, nearest-neighbor imputation, and one-standard-error selection are
#' not implemented here. [screen_covariates_lasso()] keeps its existing
#' complete-case behavior.
#'
#' @param data A `data.frame` with unique, nonmissing, nonempty column names.
#' @param response Name of a real numeric response column.
#' @param covariates At least two unique real numeric predictor column names,
#'   matched literally. Exclude the response and subject identifier.
#' @param lambda A prespecified numeric vector of at least two distinct, finite,
#'   strictly positive penalties. Values are sorted in decreasing order. Choose
#'   the grid independently of held-out outcomes and preprocessing statistics.
#'   A backend path that does not cover the full grid raises an error.
#' @param method Training replacement summary: `"mean"` or `"median"`.
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
#'
#' @return A plain list containing:
#' \describe{
#'   \item{selected}{Nonzero final-model covariates at `lambda.min`, in input order.}
#'   \item{lambda.min}{The penalty with minimum held-out mean squared error.}
#'   \item{alpha}{The supplied mixing parameter, retained for reproducibility.}
#'   \item{cv}{Data frame with decreasing `lambda` and observation-weighted `mse`.}
#'   \item{predictions}{Held-out prediction matrix, with original row names/order
#'     and columns corresponding to rows of `cv`. Excluded response rows are `NA`.}
#'   \item{foldid}{Normalized fold labels in original row order; `NA` for exclusions.}
#'   \item{fold_imputation}{Named list of training imputation tables by normalized fold.}
#'   \item{fit}{The final `glmnet` path fitted on all retained development rows.}
#'   \item{imputation}{The final training replacement table for [apply_imputation()].}
#' }
#' Save the result with [base::saveRDS()]. To predict on new data, apply
#' `imputation`, select predictors in `imputation$var` order, then call
#' [stats::predict()] on `fit` with `newx` and `s = lambda.min`. The model
#' already includes its training standardization; do not rescale new data.
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
#' new_data <- data.frame(x1 = c(NA, 1), x2 = c(1, -1))
#' completed <- apply_imputation(new_data, result$imputation)
#' predict(result$fit,
#'   newx = as.matrix(completed[result$imputation$var]),
#'   s = result$lambda.min
#' )
#' @seealso [fit_imputation()], [screen_covariates_lasso()]
#' @export
screen_covariates_lasso_imputed <- function(data, response, covariates, lambda,
                                            method = c("mean", "median"), alpha = 1,
                                            id = NULL, nfolds = 10L, foldid = NULL) {
  method <- match.arg(method)
  covariates <- validate_model_covariates(data, covariates)
  if (!is.character(response) || !is.null(dim(response)) || length(response) != 1L ||
    is.na(response) || !response %in% names(data)) {
    stop("`response` must name a real numeric column in `data`")
  }
  if (length(covariates) < 2L) {
    stop("Imputed LASSO screening requires at least two numeric covariates")
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
  vars <- c(response, covariates)
  if (!all(vapply(data[vars], is_numeric_vector, logical(1)))) {
    stop("Response and covariate columns must be real numeric vectors")
  }
  keep <- !is.na(data[[response]])
  retained <- data[keep, vars, drop = FALSE]
  if (nrow(retained) < 3L) {
    stop("At least three observed-response rows are required")
  }
  if (any(vapply(retained, function(column) any(is.infinite(column)), logical(1)))) {
    stop("Response and covariates must not contain infinite values on retained rows")
  }
  subjects <- if (is.null(id)) NULL else data[[id]]
  folds <- make_lasso_folds(keep, subjects, nfolds, foldid)
  labels <- sort(unique(folds))
  predictions <- matrix(NA_real_, nrow(retained), length(lambda))
  fold_imputation <- stats::setNames(vector("list", length(labels)), as.character(labels))
  for (fold in labels) {
    held_out <- folds == fold
    context <- sprintf("Training data excluding fold %s", fold)
    trained <- fit_imputed_lasso_path(
      retained[!held_out, , drop = FALSE], response, covariates,
      method, lambda, alpha, context
    )
    completed <- apply_imputation(retained[held_out, , drop = FALSE], trained$imputation)
    predicted <- stats::predict(trained$fit,
      newx = as.matrix(completed[covariates]), s = lambda
    )
    if (any(!is.finite(predicted))) {
      stop(sprintf("Nonfinite held-out predictions for fold %s", fold))
    }
    predictions[held_out, ] <- predicted
    fold_imputation[[as.character(fold)]] <- trained$imputation
  }
  mse <- colMeans((predictions - retained[[response]])^2)
  if (any(!is.finite(mse))) {
    stop("Held-out squared errors must be finite; review the data scale")
  }
  best <- which.min(mse)
  final <- fit_imputed_lasso_path(
    retained, response, covariates, method, lambda, alpha, "Final training data"
  )
  coefficients <- as.matrix(stats::coef(final$fit, s = lambda[best]))[-1L, 1L]
  aligned_predictions <- matrix(NA_real_, nrow(data), length(lambda),
    dimnames = list(rownames(data), paste0("lambda_", seq_along(lambda)))
  )
  aligned_predictions[keep, ] <- predictions
  aligned_folds <- rep(NA_integer_, nrow(data))
  aligned_folds[keep] <- folds
  list(
    selected = covariates[coefficients != 0], lambda.min = lambda[best], alpha = unname(alpha),
    cv = data.frame(lambda = lambda, mse = unname(mse)),
    predictions = aligned_predictions, foldid = aligned_folds,
    fold_imputation = fold_imputation, fit = final$fit,
    imputation = final$imputation
  )
}

fit_imputed_lasso_path <- function(data, response, covariates, method,
                                   lambda, alpha, context) {
  tryCatch(
    {
      if (length(unique(data[[response]])) < 2L) {
        stop("constant response")
      }
      params <- fit_imputation(data, covariates, method)
      completed <- apply_imputation(data, params)
      x <- as.matrix(completed[covariates])
      varying <- vapply(completed[covariates], function(column) {
        length(unique(column)) > 1L
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
      list(fit = fit, imputation = params)
    },
    error = function(error) {
      stop(context, ": ", conditionMessage(error), call. = FALSE)
    }
  )
}
