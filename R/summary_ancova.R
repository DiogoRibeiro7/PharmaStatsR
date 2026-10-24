#' Summarize an ANCOVA fit
#'
#' Summarize the additive model from [pharma_ancova()] using the standard
#' [stats::summary.lm()] calculations and display. The printed output also
#' includes the stored treatment-by-covariate interaction comparison and
#' adjusted means. No model is refitted and no new inferential method is added.
#'
#' @param object An object returned by [pharma_ancova()].
#' @param correlation Include the coefficient correlation matrix, as in
#'   [stats::summary.lm()].
#' @param symbolic.cor Print coefficient correlations symbolically.
#' @param x An ANCOVA summary returned by `summary()`.
#' @param digits Number of significant digits for printing.
#' @param signif.stars Display significance stars, following the R option.
#' @param ... Further arguments passed to the native linear-model summary or
#'   its print method.
#'
#' @return `summary()` returns an object of class `summary.pharma_ancova`
#'   inheriting from `summary.lm`. It retains the native summary components,
#'   including `coefficients`, `residuals`, `sigma`, `df`, `r.squared`,
#'   `adj.r.squared`, `fstatistic`, and optional `correlation`. It adds
#'   `slope_homogeneity`, `adjusted_means`, `covariate_mean`, `treatment`, and
#'   `covariate` from the fitted result. `coef(summary(result))` extracts the
#'   estimate/standard-error/t-statistic/p-value matrix. `print()` invisibly
#'   returns the summary without changing its numeric precision.
#' @details
#' The coefficient table, residual standard error, R-squared and overall F
#' statistic describe the additive model. The separate interaction F test is
#' a common-slope diagnostic; a large p-value does not establish equal slopes.
#' Adjusted means and confidence limits retain the adjustment point and
#' confidence level used by the original fit. These are individual intervals,
#' without a multiplicity adjustment. Use `summary(result$interaction_model)`
#' to inspect the interaction coefficients. Existing saved ANCOVA fits work
#' without refitting.
#' @examples
#' dat <- data.frame(
#'   response = c(11, 11, 13, 17, 14, 16, 20, 26),
#'   treatment = factor(rep(c("A", "B"), each = 4)),
#'   baseline = rep(0:3, 2)
#' )
#' fit <- pharma_ancova(response ~ treatment + baseline, dat)
#' summary(fit)
#' coef(summary(fit))
#' summary(fit)$adj.r.squared
#' print(summary(fit, correlation = TRUE), signif.stars = FALSE)
#' @export
summary.pharma_ancova <- function(object, correlation = FALSE,
                                  symbolic.cor = FALSE, ...) {
  result <- summary(object$model,
    correlation = correlation, symbolic.cor = symbolic.cor, ...
  )
  for (name in c(
    "slope_homogeneity", "adjusted_means", "covariate_mean",
    "treatment", "covariate"
  )) {
    result[[name]] <- object[[name]]
  }
  class(result) <- c("summary.pharma_ancova", class(result))
  result
}

#' @rdname summary.pharma_ancova
#' @export
print.summary.pharma_ancova <- function(x, digits = max(3L, getOption("digits") - 3L),
                                        signif.stars = getOption("show.signif.stars"), ...) {
  cat("ANCOVA: additive model\n")
  native <- x
  class(native) <- "summary.lm"
  print(native, digits = digits, signif.stars = signif.stars, ...)

  cat("\nCommon-slope diagnostic: treatment-by-covariate interaction\n")
  comparison <- matrix(
    unlist(x$slope_homogeneity[c("df1", "df2", "F", "p.value")]),
    nrow = 1L,
    dimnames = list("Interaction", c("NumDF", "DenDF", "F value", "Pr(>F)"))
  )
  stats::printCoefmat(comparison,
    digits = digits, signif.stars = signif.stars,
    cs.ind = integer(0), tst.ind = 3L, has.Pvalue = TRUE, P.values = TRUE
  )
  cat("A large interaction p-value does not establish equal slopes.\n")

  cat("\nAdjusted means and confidence limits at ", x$covariate, " = ",
    format(x$covariate_mean, digits = digits), "\n",
    sep = ""
  )
  print(x$adjusted_means, digits = digits, row.names = FALSE)
  invisible(x)
}
