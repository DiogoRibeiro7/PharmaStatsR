#' Wild bootstrap for linear models
#'
#' Applies the Rademacher wild bootstrap to obtain resampled coefficient
#' estimates for a linear model.
#'
#' @param formula Model formula for `lm`.
#' @param data Data frame containing the variables.
#' @param R Number of bootstrap replicates.
#'
#' @return A matrix of bootstrap coefficients with one row per replicate.
#' @export
#'
#' @examples
#' res <- pharma_wild_bootstrap(response ~ treatment, data = pharma_sample, R = 10)
#' head(res)
pharma_wild_bootstrap <- function(formula, data, R = 1000) {
  fit <- lm(formula, data = data)
  X <- model.matrix(fit)
  fitted <- fitted(fit)
  res <- residuals(fit)
  coef_mat <- matrix(NA_real_, nrow = R, ncol = length(coef(fit)))
  for (i in seq_len(R)) {
    w <- sample(c(-1, 1), length(res), replace = TRUE)
    y_star <- fitted + res * w
    coef_mat[i, ] <- coef(lm(y_star ~ X - 1))
  }
  colnames(coef_mat) <- names(coef(fit))
  coef_mat
}
