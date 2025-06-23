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
#'   pharma_ai_model_select(response ~ treatment, data = pharma_sample)
#' }
pharma_ai_model_select <- function(formula, data, models = c("glm", "rf"),
                                   metric = "Accuracy", trControl = NULL, ...) {
  # verify caret is available
  if (!requireNamespace("caret", quietly = TRUE)) {
    stop("Package 'caret' is required for pharma_ai_model_select()")
  }

  # default to 5-fold cross-validation if no control object supplied
  if (is.null(trControl)) {
    trControl <- caret::trainControl(method = "cv", number = 5)
  }

  # fit each candidate model using caret::train
  fits <- lapply(models, function(meth) {
    caret::train(formula, data = data, method = meth, metric = metric,
                 trControl = trControl, ...)
  })
  names(fits) <- models

  # identify the model with the best metric value
  get_metric <- function(fit) {
    res <- fit$results[[metric]]
    if (is.null(res)) NA_real_ else max(res, na.rm = TRUE)
  }
  scores <- vapply(fits, get_metric, numeric(1))
  best_idx <- which.max(scores)

  list(best_model = fits[[best_idx]], all_models = fits)
}
