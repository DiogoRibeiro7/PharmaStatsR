#' Fit an estimable two-predictor quadratic response surface
#'
#' Fit an ordinary least-squares surface with linear, squared, and interaction
#' terms for two numeric predictors. All six coefficients must be estimable.
#'
#' @param x1 A finite numeric vector for the first predictor.
#' @param x2 A finite numeric vector for the second predictor.
#' @param y A finite numeric response vector of the same length.
#' @param ... Additional named arguments passed to `stats::lm`.
#'   `subset`, `weights`, `na.action`, `offset`, `method`, and `singular.ok`
#'   are not supported because they can change the checked design or fit.
#'
#' @details
#' The model is `y = beta0 + beta1*x1 + beta2*x2 + beta11*x1^2 +
#' beta22*x2^2 + beta12*x1*x2 + error`. At least seven complete observations
#' and a full-rank six-column design matrix are required. Replication at
#' design points is allowed but not required; without replication, residual
#' error combines pure error and possible lack of fit. Inference assumes
#' independent errors with suitable variance and distribution. Scale and
#' center predictors when needed for numerical stability.
#'
#' @return An `lm` object with six estimable coefficients and positive
#'   residual degrees of freedom. Inspect `summary()` for uncertainty.
#' @examples
#' grid <- expand.grid(x1 = c(-1, 0, 1), x2 = c(-1, 0, 1), replicate = 1:2)
#' grid$y <- 10 + 2 * grid$x1 - 3 * grid$x2 + 4 * grid$x1^2 +
#'   5 * grid$x2^2 + 6 * grid$x1 * grid$x2 +
#'   ifelse(grid$replicate == 1, -1, 1)
#' summary(pharma_response_surface(grid$x1, grid$x2, grid$y))
#' @export
pharma_response_surface <- function(x1, x2, y, ...) {
  dots <- match.call(expand.dots = FALSE)$...
  excluded <- c("subset", "weights", "na.action", "offset", "method",
                "singular.ok")
  if (length(dots) > 0L &&
      (is.null(names(dots)) || any(!nzchar(names(dots))) ||
       any(names(dots) %in% excluded))) {
    stop("Additional arguments must be named; `subset`, `weights`, ",
         "`na.action`, `offset`, `method`, and `singular.ok` are not supported",
         call. = FALSE)
  }

  inputs <- list(x1 = x1, x2 = x2, y = y)
  if (!all(vapply(inputs, function(value) {
    is.numeric(value) && is.null(dim(value)) && all(is.finite(value))
  }, logical(1)))) {
    stop("x1, x2, and y must be finite numeric vectors", call. = FALSE)
  }
  n <- length(y)
  if (n < 7L || length(x1) != n || length(x2) != n) {
    stop("x1, x2, and y must have equal lengths of at least seven",
         call. = FALSE)
  }

  design <- cbind(1, x1, x2, x1^2, x2^2, x1 * x2)
  if (!all(is.finite(design)) || qr(design)$rank != 6L) {
    stop("The quadratic design must have six estimable columns; ",
         "vary both predictors across distinct design points", call. = FALSE)
  }

  fit_data <- data.frame(x1 = x1, x2 = x2, y = y)
  stats::lm(y ~ x1 + x2 + I(x1^2) + I(x2^2) + I(x1 * x2),
            data = fit_data, singular.ok = FALSE, ...)
}
