#' Automatically select the best model via caret
#'
#' Uses \code{caret::train} to evaluate multiple algorithms with cross-validation
#' and returns the highest-scoring successful fit. The function requires
#' \code{caret}; it does not substitute a different model when it is absent.
#'
#' @param formula Model formula specifying the response and predictors.
#' @param data Data frame containing the variables in \code{formula}.
#' @param models Character vector of caret model names. Default explores
#'   logistic regression (\code{"glm"}), random forest (\code{"rf"}),
#'   support vector machines (\code{"svmLinear"}), and gradient boosting
#'   (\code{"gbm"}). Some candidates require additional model-engine packages.
#' @param metric Performance metric to optimize. Defaults to \code{"Accuracy"}.
#' @param trControl Optional \code{caret::trainControl} object. If \code{NULL},
#'   5-fold cross-validation is used.
#' @param explain Logical; if \code{TRUE}, compute variable importance for each
#'   fitted model using \code{caret::varImp}.
#' @param ... Additional arguments passed to \code{caret::train}.
#'
#' @details If \code{caret} is unavailable, the call errors with an installation
#'   instruction before fitting any model. Individual candidate failures are
#'   warned and omitted, so inspect \code{all_models} to see what ran.
#'
#' @return A list with \code{best_model}, the highest-scoring caret model;
#'   \code{all_models}, the successfully fitted candidates; and
#'   \code{variable_importance}, a list when \code{explain = TRUE} or
#'   \code{NULL} otherwise. Failed candidate fits produce warnings.
#' @export
#'
#' @examples
#' if (requireNamespace("caret", quietly = TRUE)) {
#'   pharma_ai_model_select(
#'     outcome ~ treatment,
#'     data = pharma_sample,
#'     models = "glm", metric = "Accuracy"
#'   )
#' }
pharma_ai_model_select <- function(formula, data,
                                   models = c("glm", "rf", "svmLinear", "gbm"),
                                   metric = "Accuracy", trControl = NULL,
                                   explain = FALSE, ...) {
  if (!.pharma_caret_available()) {
    stop("Package 'caret' is required for pharma_ai_model_select(); ",
         "install it with install.packages('caret'). No model was fitted.",
         call. = FALSE)
  }

  # Ensure the formula references columns present in `data` before training
  # to avoid hard-to-debug errors during caret model fitting.
  tryCatch(stats::model.frame(formula, data = data),
    error = function(e) stop("Invalid formula: ", e$message)
  )

  # Convert a numeric binary response to factor if using a classification metric
  response_var <- all.vars(formula)[1]
  if (metric == "Accuracy" && is.numeric(data[[response_var]]) &&
    length(unique(data[[response_var]])) == 2) {
    data[[response_var]] <- factor(data[[response_var]])
  }

  # Default to 5-fold cross-validation if the caller did not supply a
  # custom trainControl object. This provides reasonable resampling
  # without requiring users to understand caret internals.
  if (is.null(trControl)) {
    trControl <- caret::trainControl(method = "cv", number = 5)
  }

  # fit each candidate model using caret::train
  fits <- lapply(models, function(meth) {
    tryCatch(
      caret::train(formula,
        data = data, method = meth, metric = metric,
        trControl = trControl, ...
      ),
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

  # compute variable importance for each model if requested
  variable_importance <- NULL
  if (explain) {
    variable_importance <- lapply(seq_along(fits), function(i) {
      meth <- names(fits)[i]
      fit <- fits[[i]]
      tryCatch(
        caret::varImp(fit),
        error = function(e) {
          warning(sprintf(
            "Variable importance failed for model %s: %s",
            meth, e$message
          ))
          NULL
        }
      )
    })
    names(variable_importance) <- names(fits)
  }

  # return best-performing model, all candidate fits, and importance metrics
  list(
    best_model = fits[[best_idx]],
    all_models = fits,
    variable_importance = variable_importance
  )
}

# Keep dependency detection local to this package so the missing-backend
# behavior can be exercised even on CI runners with caret installed.
.pharma_caret_available <- function() {
  requireNamespace("caret", quietly = TRUE)
}
