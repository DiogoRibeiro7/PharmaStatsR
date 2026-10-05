#' Global permutation F-test for a linear model
#'
#' Compare all non-intercept predictors jointly against an intercept-only
#' model (or a zero-mean model if the formula omits the intercept). The
#' evaluated response is permuted across the observations used by
#' `stats::lm()`, keeping the design matrix and analysis rows fixed.
#'
#' @param formula A two-sided linear-model formula with a numeric response.
#' @param data A data frame containing the model variables.
#' @param R A positive whole number of random response permutations.
#' @param ... Additional arguments passed to `stats::lm()`, such as
#'   `subset` or `na.action`. Weights and offsets are unsupported.
#'
#' @return A list with `statistic`, the observed global F value;
#'   `perm`, a numeric vector of `R` permuted global F values; and
#'   `p.value`, the Monte Carlo upper-tail p-value using
#'   `(1 + exceedances) / (R + 1)`, including numerical ties as
#'   described below.
#' @details
#' Raw-response permutations test the global null that none of the
#' non-intercept predictors are associated with the response. They
#' require exchangeable observations under that null. They do not
#' isolate a treatment effect after adjusting for nuisance predictors,
#' and are not suitable for clustered, repeated, or time-ordered data
#' without an appropriate restricted permutation scheme.
#'
#' For a finite observed statistic, upper-tail comparisons include values
#' within `100 * .Machine$double.eps * abs(statistic)` below it as numerical
#' ties. Infinite statistics are compared directly. Returned F values are
#' not rounded. This narrow tolerance addresses floating-point differences
#' between theoretically equal statistics, not ill-conditioned model fits.
#' @references
#' R documentation for sequential ANOVA tables:
#' \url{https://stat.ethz.ch/R-manual/R-devel/library/stats/html/anova.lm.html}
#' @export
#'
#' @examples
#' independent <- data.frame(
#'   response = c(1, 2, 2, 4, 2, 3, 5, 7),
#'   group = rep(c("A", "B"), each = 4),
#'   dose = rep(1:4, times = 2)
#' )
#' set.seed(7)
#' pharma_perm_f_test(response ~ group + dose, data = independent, R = 50)
pharma_perm_f_test <- function(formula, data, R = 1000, ...) {
  if (!inherits(formula, "formula") || length(formula) != 3L) {
    stop("`formula` must be a two-sided model formula", call. = FALSE)
  }
  if (!is.data.frame(data)) {
    stop("`data` must be a data frame", call. = FALSE)
  }
  if (!is.numeric(R) || length(R) != 1L || !is.finite(R) ||
      R < 1 || R %% 1 != 0 || R > .Machine$integer.max) {
    stop("`R` must be a positive whole number within the supported range",
         call. = FALSE)
  }

  # Preserve lm's non-standard evaluation of subset and other dot arguments.
  lm_call <- match.call(expand.dots = TRUE)
  lm_call[[1L]] <- quote(stats::lm)
  lm_call$R <- NULL
  model <- eval(lm_call, envir = parent.frame())
  model_frame <- stats::model.frame(model)
  response <- stats::model.response(model_frame)
  if (!is.numeric(response) || !is.null(dim(response)) ||
      any(!is.finite(response))) {
    stop("The evaluated response must be a finite numeric vector",
         call. = FALSE)
  }
  if (!is.null(model$weights) || !is.null(model$offset) ||
      !is.null(stats::model.weights(model_frame)) ||
      !is.null(stats::model.offset(model_frame))) {
    stop("Weights and offsets are not supported for response permutations",
         call. = FALSE)
  }

  has_intercept <- attr(stats::terms(model), "intercept") == 1L
  df_model <- model$rank - as.integer(has_intercept)
  df_residual <- model$df.residual
  if (df_model < 1L || df_residual < 1L) {
    stop("The model needs a predictor and positive residual degrees of freedom",
         call. = FALSE)
  }
  design <- stats::model.matrix(model)
  global_f <- function(y) {
    fit <- stats::lm.fit(design, y)
    rss <- sum(fit$residuals^2)
    null_rss <- if (has_intercept) sum((y - mean(y))^2) else sum(y^2)
    if (!is.finite(rss) || !is.finite(null_rss) ||
        null_rss <= 0) {
      stop("The global F statistic is undefined for this response",
           call. = FALSE)
    }
    if (rss == 0) {
      return(Inf)
    }
    max(0, (null_rss - rss) / df_model) / (rss / df_residual)
  }

  observed <- global_f(response)
  permutations <- vapply(seq_len(R), function(i) {
    global_f(response[sample.int(length(response))])
  }, numeric(1))
  # QR refits can place mathematically tied statistics a few ulps apart.
  # Do not subtract an infinite tolerance when the observed F is infinite.
  tie_tolerance <- if (is.finite(observed)) {
    100 * .Machine$double.eps * abs(observed)
  } else {
    0
  }
  exceedances <- sum(permutations >= observed - tie_tolerance)
  list(
    statistic = observed,
    perm = permutations,
    p.value = (1 + exceedances) / (R + 1)
  )
}
