#' Automatically select the best model via caret
#'
#' Uses \code{caret::train} to evaluate multiple algorithms with cross-validation
#' and returns the model achieving the highest performance.
#'
#' @param formula Model formula specifying the response and predictors.
#' @param data Data frame containing the variables in \code{formula}.
#' @param models Character vector of caret model names. Default includes
#'   logistic regression (\code{"glm"}) and random forest (\code{"rf"}).
#' @param metric Performance metric to optimize. Defaults to \code{"Accuracy"}.
#' @param trControl Optional \code{caret::trainControl} object. If \code{NULL},
#'   5-fold cross-validation is used.
#' @param ... Additional arguments passed to \code{caret::train}.
#'
#' @return A list with two elements: \code{best_model}, the highest performing
#'   caret model object, and \code{all_models}, the list of all fitted models.
#' @export
#'
#' @examples
#' if (requireNamespace("caret", quietly = TRUE)) {
#'   pharma_ai_model_select(
    response ~ treatment,
    data = pharma_sample,
    models = c("glm", "rf", "svmLinear"),
    metric = "Accuracy"
  )
#' }
pharma_ai_model_select <- function(formula, data, models = c("glm", "rf"),
                                   metric = "Accuracy", trControl = NULL, ...) {
  # Attempt to load caret for model training. If unavailable, fall back to a
  # simple `glm` fit and return that model only.
  if (!requireNamespace("caret", quietly = TRUE)) {
    warning(
      "Package 'caret' is not installed; falling back to glm() without tuning."
    )
    # Fit a basic logistic regression as a simple fallback so the user
    # still receives a reasonable model object.
    base_fit <- stats::glm(formula, data = data, family = stats::binomial())
    return(list(best_model = base_fit, all_models = list(glm = base_fit)))
  }

  # Ensure the formula references columns present in `data` before training
  # to avoid hard-to-debug errors during caret model fitting.
  tryCatch(stats::model.frame(formula, data = data),
           error = function(e) stop("Invalid formula: ", e$message))

  # Default to 5-fold cross-validation if the caller did not supply a
  # custom trainControl object. This provides reasonable resampling
  # without requiring users to understand caret internals.
  if (is.null(trControl)) {
    trControl <- caret::trainControl(method = "cv", number = 5)
  }

  # fit each candidate model using caret::train
  fits <- lapply(models, function(meth) {
    tryCatch(
      caret::train(formula, data = data, method = meth, metric = metric,
                   trControl = trControl, ...),
      error = function(e) {
        warning(sprintf("Model %s failed to fit: %s", meth, e$message))
        NULL
      }
    )
  })
  names(fits) <- models
  # drop models that failed during training
  fits <- Filter(Negate(is.null), fits)

  # ensure we have at least one successfully fitted model
  if (length(fits) == 0) {
    stop("None of the candidate models could be fit")
  }

  # validate that the requested metric exists in the results
  available_metrics <- unique(unlist(lapply(fits, function(f) names(f$results))))
  if (!metric %in% available_metrics) {
    stop(sprintf(
      "Metric '%s' not found in model results. Available metrics: %s",
      metric, paste(available_metrics, collapse = ", ")
    ))
  }

  # identify the model with the best metric value
  get_metric <- function(fit) {
    res <- fit$results[[metric]]
    if (is.null(res)) NA_real_ else max(res, na.rm = TRUE)
  }
  # compute the chosen metric for all candidate models so we can
  # determine which one performed the best during resampling
  scores <- vapply(fits, get_metric, numeric(1))
  best_idx <- which.max(scores)

  # return best-performing model and all candidate fits
  list(best_model = fits[[best_idx]], all_models = fits)
}
