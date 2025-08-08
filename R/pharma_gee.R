#' Fit a generalized estimating equations (GEE) model
#'
#' Convenience wrapper around `geepack::geeglm` for correlated response data.
#' The function validates its inputs and ensures the `geepack` package is
#' available before fitting the model.
#'
#' @param formula A model formula.
#' @param id A cluster identifier for repeated observations.
#' @param data Data frame containing the variables in the model.
#' @param family Error distribution and link function to be used in the model.
#' @param corstr Working correlation structure. See `geepack::geeglm`.
#' @param ... Additional arguments passed to `geepack::geeglm`.
#'
#' @return A `geeglm` object.
#' @export
#'
#' @examples
#' pharma_gee(response ~ condition, id = subject, data = pharma_repeated)
pharma_gee <- function(formula, id, data, family = gaussian, corstr = "independence", ...) {
  validate_inputs(data, formula)
  if (!requireNamespace("geepack", quietly = TRUE)) {
    stop(
      "Package 'geepack' is required for `pharma_gee()`.\n",
      "Please install it with: install.packages('geepack')"
    )
  }
  geepack::geeglm(
    formula = formula,
    id = id,
    data = data,
    family = family,
    corstr = corstr,
    ...
  )
}
