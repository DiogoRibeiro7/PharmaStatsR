#' Pool models across multiply imputed datasets
#'
#' Fits a model to each imputed dataset using `glm` or `lm` and pools the
#' results. This does not vary the missingness assumptions or perform a
#' missing-not-at-random sensitivity analysis. Requires the optional **mice**
#' package.
#'
#' @param mids_obj A `mids` object produced by [pharma_mice_impute()] or
#'   `mice::mice`.
#' @param formula Model formula to fit.
#' @param family Optional glm family. If `NULL`, a linear model is fitted.
#' @param ... Additional arguments passed to the model fitting function.
#'
#' @return A `mipo` pooled model from `mice::pool`.
#' @export
#'
#' @examples
#' if (requireNamespace("mice", quietly = TRUE)) {
#'   dat <- pharma_sample
#'   dat$response[1] <- NA
#'   imp <- pharma_mice_impute(dat, m = 2, maxit = 1)
#'   pharma_sensitivity_analysis(imp, response ~ treatment)
#' }
pharma_sensitivity_analysis <- function(mids_obj, formula, family = NULL, ...) {
  if (!.pharma_mice_available()) {
    stop(
      "Optional package 'mice' is required for pharma_sensitivity_analysis(). Install it with install.packages('mice').",
      call. = FALSE
    )
  }
  completed <- mice::complete(mids_obj, action = "all")
  fits <- lapply(completed, function(dataset) {
    if (is.null(family)) {
      stats::lm(formula, data = dataset, ...)
    } else {
      stats::glm(formula, data = dataset, family = family, ...)
    }
  })
  mice::pool(fits)
}
