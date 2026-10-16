#' Predict from a saved imputed-LASSO screening result
#'
#' Applies the final saved imputer from [screen_covariates_lasso_imputed()],
#' restores the complete training predictor order, and predicts with its fitted
#' Gaussian model. No imputation, scaling, model fitting, or tuning is learned
#' from the supplied rows. This is an experimental API.
#'
#' Mean/median results use [apply_imputation()]; nearest-neighbor results use
#' [apply_knn_imputation()] with the saved training donors and distance scales.
#' Missing values without comparable kNN donors raise a prediction-context
#' error. Rows are not dropped and there is no fallback imputation.
#'
#' Supply raw predictors, including candidates whose final coefficients
#' are zero. Extra columns are ignored; no response or subject identifier is
#' required. Numeric missing values (`NA`/`NaN`) are allowed when the saved
#' imputer can fill them; infinite values and incompatible column types fail.
#' Do not impute or rescale new data first. The fitted model already accounts
#' for training standardization.
#'
#' Results fitted with `encode = TRUE` also reuse their saved [fit_encoding()]
#' recipe, after numeric imputation. Categorical inputs must be observed and
#' known to the recipe; factors or characters may supply categorical values,
#' while logical candidates must stay logical. Later contrast options and
#' unused new factor levels do not change the saved coding. Supply all original
#' raw candidates, not their indicator columns. No encoding is learned from
#' the prediction batch. kNN retains its saved distance schema as well.
#'
#' Only penalties from `object$cv$lambda` are accepted, with exact matching to
#' that recorded grid. The helper predicts the stored model path and selects
#' its columns; it does not interpolate between penalties or refit. Predictions
#' use the final model trained on all retained development rows, and differ
#' from the held-out predictions in `object$predictions`.
#'
#' Saved results can be restored with [base::readRDS()] in a fresh R session.
#' This helper loads the declared `glmnet` dependency to register its methods;
#' callers need only load PharmaStatsR. Older mean/median results lacking both
#' `method` and `covariates` metadata are supported when their original
#' replacement table supplies those values. Other incomplete or inconsistent
#' prediction inputs raise errors. Treat fitted results as output, not an
#' editing interface.
#'
#' @param object Result from [screen_covariates_lasso_imputed()], or its RDS
#'   round trip. Its final imputation parameters, Gaussian model, selected
#'   penalty, recorded penalty grid, and encoding recipe (if fitted) must
#'   remain available and consistent.
#' @param newdata Data frame containing every original candidate predictor,
#'   matched by literal name. Column order may differ; empty data are allowed.
#' @param lambda Optional nonempty vector of distinct penalties from
#'   `object$cv$lambda`, in the desired output order. `NULL` uses
#'   `object$lambda.min`. New, interpolated, or extrapolated penalties are rejected.
#'
#' @return A numeric matrix with one row per new observation and one column
#'   per requested penalty, even for a single row or penalty. Row order and
#'   names follow `newdata`. Column `lambda_j` corresponds to row `j` of
#'   `object$cv`; columns follow the requested penalty order. Input data and
#'   fitted results are not modified. Values are final-model predictions,
#'   without prediction intervals or post-selection inference.
#' @examples
#' block <- data.frame(
#'   x1 = c(-1, -1, 1, 1, NA, NA), x2 = c(-1, 1, -1, 1, -1, 1),
#'   y = c(-2, -2, 2, 2, 0, 0)
#' )
#' training <- block[rep(seq_len(6), 3), ]
#' result <- screen_covariates_lasso_imputed(
#'   training, "y", c("x1", "x2"),
#'   lambda = c(2, 1, 0.5),
#'   method = "knn", k = 2, foldid = rep(1:3, each = 6)
#' )
#' future <- data.frame(x2 = c(1, -1, 1), x1 = c(NA, 1, -1))
#' predict_lasso_imputed(result, future)
#' predict_lasso_imputed(result, future, lambda = c(0.5, 2))
#' @seealso [screen_covariates_lasso_imputed()], [apply_imputation()],
#'   [apply_knn_imputation()], [apply_encoding()]
#' @export
predict_lasso_imputed <- function(object, newdata, lambda = NULL) {
  # RDS restoration does not itself register the backend's S3 methods.
  loadNamespace("glmnet")
  specification <- validate_lasso_prediction(object)
  if (is.null(lambda)) lambda <- object$lambda.min
  if (!is_numeric_vector(lambda) || length(lambda) == 0L ||
    any(!is.finite(lambda)) || anyDuplicated(lambda)) {
    stop("`lambda` must be a nonempty vector of distinct fitted penalties")
  }
  selected <- match(lambda, specification$grid)
  if (anyNA(selected)) {
    stop("Every requested `lambda` must be a value in `object$cv$lambda`")
  }
  completed <- tryCatch(
    apply_lasso_design(
      newdata, object$imputation, specification$method,
      specification$covariates, specification$encoding
    ),
    error = function(error) {
      stop("Prediction data: ", conditionMessage(error), call. = FALSE)
    }
  )
  labels <- paste0("lambda_", selected)
  if (nrow(completed) == 0L) {
    return(matrix(numeric(0), 0L, length(selected), dimnames = list(NULL, labels)))
  }
  values <- stats::predict(object$fit,
    newx = completed, type = "response"
  )
  values <- as.matrix(values)[, selected, drop = FALSE]
  if (!identical(dim(values), c(nrow(newdata), length(selected))) ||
    any(!is.finite(values))) {
    stop("Prediction values must be finite; review the predictor scale and saved model")
  }
  dimnames(values) <- list(rownames(newdata), labels)
  values
}

validate_lasso_prediction <- function(object) {
  invalid <- function(detail) {
    stop("Invalid screening result: ", detail, call. = FALSE)
  }
  required <- c("fit", "imputation", "cv", "lambda.min")
  if (!is.list(object) || !valid_encoding_names(names(object)) ||
    !all(required %in% names(object))) {
    invalid("use a saved result from screen_covariates_lasso_imputed()")
  }
  params <- object$imputation
  method <- object[["method", exact = TRUE]]
  covariates <- object[["covariates", exact = TRUE]]
  if (is.null(method) && is.null(covariates) && is.data.frame(params)) {
    method <- unique(params$method)
    covariates <- params$var
  }
  if (!is.character(method) || !is.null(dim(method)) || length(method) != 1L ||
    is.na(method) || !method %in% c("mean", "median", "knn")) {
    invalid("missing or unsupported imputation method")
  }
  encoding <- object[["encoding", exact = TRUE]]
  if (!valid_encoding_names(covariates) || length(covariates) < if (is.null(encoding)) 2L else 1L) {
    invalid("missing or invalid candidate predictor order")
  }
  numeric_vars <- columns <- covariates
  if (!is.null(encoding)) {
    validate_encoding_recipe(encoding)
    if (!identical(names(encoding$variables), covariates) || length(encoding$columns) < 2L) {
      invalid("encoding disagrees with the candidate predictor order or design size")
    }
    numeric_vars <- covariates[vapply(encoding$variables, function(variable) {
      variable$kind == "numeric"
    }, logical(1))]
    columns <- encoding$columns
  }
  if (method == "knn") {
    if (!is.list(params) || !identical(params$vars, numeric_vars)) {
      invalid("donor model targets disagree with the candidate predictor order")
    }
  } else {
    validate_imputation_params(params)
    if (!identical(params$var, numeric_vars) || !is.character(params$method) ||
      anyNA(params$method) || length(params$method) != length(numeric_vars) ||
      any(params$method != method)) {
      invalid("replacement table disagrees with the imputation method or predictor order")
    }
  }
  if (!is.data.frame(object$cv) || !valid_encoding_names(names(object$cv)) ||
    !"lambda" %in% names(object$cv)) {
    invalid("missing penalty grid")
  }
  grid <- object$cv$lambda
  if (!is_numeric_vector(grid) || length(grid) < 2L ||
    any(!is.finite(grid)) || any(grid <= 0) || any(diff(grid) >= 0)) {
    invalid("penalty grid must be finite, positive, and strictly decreasing")
  }
  best <- object$lambda.min
  if (!is_numeric_vector(best) || length(best) != 1L ||
    !is.finite(best) || !best %in% grid) {
    invalid("selected penalty is absent from the fitted grid")
  }
  fit <- object$fit
  if (!is.list(fit) || !inherits(fit, "elnet") || !inherits(fit, "glmnet") || inherits(fit, "relaxed") ||
    !isTRUE(all.equal(unname(fit$lambda), unname(grid), tolerance = 1e-12))) {
    invalid("Gaussian model path disagrees with the recorded penalty grid")
  }
  coefficients <- tryCatch(as.matrix(stats::coef(fit)), error = function(error) {
    invalid("cannot read the saved model coefficients")
  })
  if (!identical(dim(coefficients), c(length(columns) + 1L, length(grid))) ||
    !identical(rownames(coefficients)[-1L], columns) ||
    any(!is.finite(coefficients))) {
    invalid("model coefficients disagree with the candidate predictor order or are nonfinite")
  }
  list(method = method, covariates = covariates, grid = grid, encoding = encoding)
}
