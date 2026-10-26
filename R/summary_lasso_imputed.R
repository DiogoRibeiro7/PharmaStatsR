#' Summarize an imputed LASSO screening result
#'
#' Show the final penalized coefficients at the selected fitted penalty,
#' cross-validation tuning error, preprocessing settings, selected candidates,
#' and analysis-row/fold counts from [screen_covariates_lasso_imputed()].
#' No model fitting, imputation, encoding or tuning is repeated.
#'
#' @param object A result from [screen_covariates_lasso_imputed()].
#' @param x A summary returned by `summary()` for that result.
#' @param digits Number of significant digits for printing.
#' @param ... No additional arguments for `summary()`. For `print()`, further
#'   formatting arguments passed to [stats::printCoefmat()].
#'
#' @return `summary()` returns a `summary.pharma_lasso_imputed` list with:
#' \describe{
#'   \item{coefficients}{A one-column `Estimate` matrix including the intercept
#'     and every final design column, including coefficients shrunk to zero.
#'     `coef(summary(result))` extracts this matrix.}
#'   \item{lambda.min, mse.min}{Selected penalty and its stored held-out MSE.}
#'   \item{cv}{The stored penalty/MSE curve, in decreasing penalty order.}
#'   \item{alpha, method, encoded}{Mixing parameter, imputation method, and
#'     whether categorical encoding was fitted.}
#'   \item{nobs, n.excluded, nfolds}{Retained rows, excluded response rows, and
#'     the number of nonempty held-out folds. These are row counts, not subjects.}
#'   \item{covariates, selected, selected_columns}{All raw candidates, stored
#'     selected raw candidates, and nonzero final design-column names.}
#' }
#' `print()` invisibly returns its input without rounding the stored values.
#' @details
#' Coefficients use the selected column of the saved Gaussian model path,
#' without interpolation. They describe the final model fitted on all retained
#' development rows. Held-out MSE gives each retained observation equal weight;
#' the minimum is tuning error, not an unbiased estimate of future performance.
#' The summary supplies no ordinary least-squares standard errors, t tests,
#' p-values or post-selection inference. It does not inherit from `summary.lm`.
#'
#' With encoding, coefficients refer to design columns while `selected` refers
#' to raw candidates. Penalties act on individual design columns, so selection
#' depends on coding and is not a grouped test. Literal coefficient labels are
#' retained, including a candidate named `(Intercept)`; the first coefficient
#' row is always the fitted intercept.
#'
#' New results carry the summary class and retain their existing list entries
#' and prediction behavior. Older saved plain lists can opt in without refitting
#' using `class(result) <- c("pharma_lasso_imputed", "list")`. This only enables
#' dispatch; required model, CV, fold and selection metadata must still be
#' available and consistent. Load PharmaStatsR before summarizing restored fits.
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
#' s <- summary(fit)
#' s
#' coef(s)
#' s$cv
#' print(s, digits = 6)
#' @seealso [predict_lasso_imputed()]
#' @export
summary.pharma_lasso_imputed <- function(object, ...) {
  if (length(list(...))) {
    stop("No additional arguments are supported by this summary", call. = FALSE)
  }
  # Restoring an RDS does not register the saved backend's S3 methods.
  loadNamespace("glmnet")
  specification <- validate_lasso_prediction(object)
  invalid <- function(detail) {
    stop("Invalid screening result: ", detail, call. = FALSE)
  }
  mse <- object$cv$mse
  if (!is_numeric_vector(mse) || length(mse) != length(specification$grid) ||
    any(!is.finite(mse)) || any(mse < 0)) {
    invalid("CV errors must be finite nonnegative values for every fitted penalty")
  }
  best <- match(object$lambda.min, specification$grid)
  if (best != which.min(mse)) {
    invalid("selected penalty disagrees with the minimum CV error and tie rule")
  }
  alpha <- object$alpha
  if (!is_numeric_vector(alpha) || length(alpha) != 1L ||
    !is.finite(alpha) || alpha < 0 || alpha > 1) {
    invalid("missing or invalid mixing parameter")
  }
  folds <- object$foldid
  retained <- !is.na(folds)
  if (!is_numeric_vector(folds) || !length(folds) ||
    any(!is.finite(folds[retained])) || any(folds[retained] < 1) ||
    any(folds[retained] != floor(folds[retained])) ||
    length(unique(folds[retained])) < 3L ||
    !isTRUE(all.equal(as.numeric(object$fit$nobs), as.numeric(sum(retained))))) {
    invalid("fold labels must describe the retained model rows and at least three folds")
  }
  selected <- object$selected
  if (!is.character(selected) || !is.null(dim(selected)) || anyNA(selected) ||
    anyDuplicated(selected) || !all(selected %in% specification$covariates)) {
    invalid("selected candidates must be unique original predictor names")
  }
  coefficients <- as.matrix(stats::coef(object$fit))[, best, drop = FALSE]
  colnames(coefficients) <- "Estimate"
  slopes <- coefficients[-1L, 1L]
  structure(list(
    coefficients = coefficients,
    lambda.min = object$lambda.min, mse.min = unname(mse[best]),
    cv = object$cv, alpha = alpha, method = specification$method,
    encoded = !is.null(specification$encoding),
    nobs = sum(retained), n.excluded = sum(!retained),
    nfolds = length(unique(folds[retained])),
    covariates = specification$covariates, selected = selected,
    selected_columns = names(slopes)[slopes != 0]
  ), class = "summary.pharma_lasso_imputed")
}

#' @rdname summary.pharma_lasso_imputed
#' @export
print.summary.pharma_lasso_imputed <- function(x, digits = max(3L, getOption("digits") - 3L), ...) {
  cat("Imputed Gaussian LASSO / elastic-net screening\n\n")
  cat("Rows: ", x$nobs, " retained, ", x$n.excluded,
    " excluded; folds: ", x$nfolds, "\n",
    sep = ""
  )
  cat("Imputation: ", x$method, "; categorical encoding: ",
    if (x$encoded) "yes" else "no", "\n",
    sep = ""
  )
  cat("Alpha: ", format(x$alpha, digits = digits),
    "; selected lambda: ", format(x$lambda.min, digits = digits), "\n",
    sep = ""
  )
  cat("\nPenalized coefficients at the selected lambda:\n")
  stats::printCoefmat(x$coefficients,
    digits = digits, cs.ind = integer(0), tst.ind = integer(0),
    has.Pvalue = FALSE, P.values = FALSE, signif.stars = FALSE, ...
  )
  cat("\nSelected raw covariates: ",
    if (length(x$selected)) paste(encodeString(x$selected, quote = '"'), collapse = ", ") else "(none)",
    "\n",
    sep = ""
  )
  cat("Minimum held-out MSE: ", format(x$mse.min, digits = digits), "\n", sep = "")
  cat("CV MSE is tuning error; coefficients are penalized estimates.\n")
  invisible(x)
}
