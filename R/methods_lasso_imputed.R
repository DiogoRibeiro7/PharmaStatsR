#' Coefficients and predictions for an imputed LASSO fit
#'
#' Use the standard R model interface with a saved result from
#' [screen_covariates_lasso_imputed()]. Both methods select columns of the
#' stored Gaussian model path. They do not refit, interpolate penalties, or
#' draw random numbers.
#'
#' @param object A classed result from [screen_covariates_lasso_imputed()].
#' @param newdata Data frame containing every original candidate predictor,
#'   matched by literal name, including candidates with zero coefficients.
#'   Supply raw predictors; saved imputation and optional encoding are applied.
#'   `newdata` is required, and empty data frames are allowed.
#' @param lambda Optional nonempty vector of distinct penalties from
#'   `object$cv$lambda`, in the desired output order. `NULL` uses
#'   `object$lambda.min`. New, interpolated, or extrapolated penalties fail.
#' @param ... No additional arguments are supported. In particular, these
#'   methods do not accept backend `s`, `type`, or `exact` arguments or
#'   prediction-interval options.
#'
#' @return `coef()` returns a numeric matrix with one row for the intercept
#'   followed by every final design column, including zero coefficients.
#'   `predict()` returns a numeric matrix with one row per new observation,
#'   retaining input row order and names. Both keep a matrix shape for a
#'   single penalty; column `lambda_j` refers to row `j` of `object$cv`.
#'   Requested penalty order is preserved.
#' @details
#' Coefficients describe the final penalized fit on all retained development
#' rows and account for training standardization. With encoding, coefficient
#' labels refer to design columns, while `object$selected` contains raw
#' candidate names. Literal labels are retained, including a predictor named
#' `(Intercept)`; the first row is always the fitted intercept.
#'
#' `predict()` delegates to [predict_lasso_imputed()] and has the same saved
#' preprocessing, input validation, and no-donor behavior. All original
#' predictors must be supplied even if their coefficients are zero. Predictions
#' differ from the held-out values in `object$predictions`. No standard errors,
#' confidence/prediction intervals, or post-selection inference are added.
#'
#' Load PharmaStatsR before using a result restored with [base::readRDS()].
#' The methods load the glmnet namespace to register saved backend methods.
#' Older plain-list results can opt into dispatch with
#' `class(object) <- c("pharma_lasso_imputed", "list")`; required saved model
#' and preprocessing metadata must remain available and consistent. The
#' explicit prediction helper continues to accept older plain lists.
#' @examples
#' block <- data.frame(
#'   x1 = c(-1, -1, 1, 1, NA, NA), x2 = c(-1, 1, -1, 1, -1, 1),
#'   y = c(-2, -2, 2, 2, 0, 0)
#' )
#' training <- block[rep(seq_len(6), 3), ]
#' fit <- screen_covariates_lasso_imputed(
#'   training, "y", c("x1", "x2"),
#'   lambda = c(2, 1, 0.5),
#'   foldid = rep(1:3, each = 6)
#' )
#' future <- data.frame(x1 = c(NA, 1, -1), x2 = c(1, -1, 1))
#' coef(fit)
#' predict(fit, future)
#' coef(fit, lambda = c(0.5, 2))
#' predict(fit, future, lambda = c(0.5, 2))
#' @seealso [summary.pharma_lasso_imputed()], [predict_lasso_imputed()]
#' @export
coef.pharma_lasso_imputed <- function(object, lambda = NULL, ...) {
  if (length(list(...))) {
    stop("No additional arguments are supported by this coefficient method", call. = FALSE)
  }
  loadNamespace("glmnet")
  specification <- validate_lasso_prediction(object)
  selected <- lasso_penalty_indices(lambda, specification$grid, object$lambda.min)
  coefficients <- specification$coefficients[, selected, drop = FALSE]
  colnames(coefficients) <- paste0("lambda_", selected)
  coefficients
}

#' @rdname coef.pharma_lasso_imputed
#' @export
predict.pharma_lasso_imputed <- function(object, newdata, lambda = NULL, ...) {
  if (length(list(...))) {
    stop("No additional arguments are supported by this prediction method", call. = FALSE)
  }
  predict_lasso_imputed(object, newdata, lambda = lambda)
}
