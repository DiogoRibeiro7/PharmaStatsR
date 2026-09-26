#' Fit a simple response-surface model
#'
#' Creates a second-order polynomial model for two predictors.
#'
#' @param x1 First predictor.
#' @param x2 Second predictor.
#' @param y Response variable.
#' @param ... Additional arguments passed to `stats::lm`.
#'
#' @return An `lm` object representing the fitted surface.
#' @examples
#' pharma_response_surface(
#'   pharma_dose_response$dose, pharma_dose_response$dose,
#'   pharma_dose_response$response
#' )
#' @export
pharma_response_surface <- function(x1, x2, y, ...) {
  stats::lm(y ~ x1 + x2 + I(x1^2) + I(x2^2) + I(x1 * x2), ...)
}
