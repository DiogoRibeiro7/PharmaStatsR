#' Conduct a meta-analysis
#'
#' Wrapper around `metafor::rma` to fit fixed- or random-effects models.
#'
#' @param yi Numeric vector of effect size estimates.
#' @param vi Numeric vector of effect size variances.
#' @param method Estimation method. Use "FE" for fixed effects or
#'   e.g. "REML" for random effects (default).
#' @param ... Additional arguments passed to [metafor::rma].
#'
#' @return A `rma` object.
#' @export
#'
#' @examples
#' pharma_meta_analysis(yi = c(0.2, 0.1, -0.1), vi = c(0.05, 0.04, 0.06))
pharma_meta_analysis <- function(yi, vi, method = "REML", ...) {
  metafor::rma(yi = yi, vi = vi, method = method, ...)
}

#' Forest plot for a meta-analysis
#'
#' Create a forest plot from an `rma` object.
#'
#' @param model An object from [metafor::rma].
#' @param ... Additional arguments passed to [metafor::forest].
#'
#' @return A plot.
#' @export
#'
#' @examples
#' res <- pharma_meta_analysis(yi = c(0.2, 0.1, -0.1), vi = c(0.05, 0.04, 0.06))
#' pharma_forest_plot(res)
pharma_forest_plot <- function(model, ...) {
  metafor::forest(model, ...)
}

#' Funnel plot for a meta-analysis
#'
#' Create a funnel plot from an `rma` object.
#'
#' @param model An object from [metafor::rma].
#' @param ... Additional arguments passed to [metafor::funnel].
#'
#' @return A plot.
#' @export
#'
#' @examples
#' res <- pharma_meta_analysis(yi = c(0.2, 0.1, -0.1), vi = c(0.05, 0.04, 0.06))
#' pharma_funnel_plot(res)
pharma_funnel_plot <- function(model, ...) {
  metafor::funnel(model, ...)
}

#' Meta-regression
#'
#' Wrapper around `metafor::rma` to fit a meta-regression with moderators.
#'
#' @param yi Effect size estimates.
#' @param vi Effect size variances.
#' @param mods Moderator matrix or formula.
#' @param method Estimation method for random effects (default "REML").
#' @param ... Additional arguments passed to [metafor::rma].
#'
#' @return A `rma` object.
#' @export
#'
#' @examples
#' mods <- cbind(size = c(100, 120, 80))
#' pharma_meta_regression(
#'   yi = c(0.2, 0.1, -0.1),
#'   vi = c(0.05, 0.04, 0.06),
#'   mods = mods
#' )
pharma_meta_regression <- function(yi, vi, mods, method = "REML", ...) {
  metafor::rma(yi = yi, vi = vi, mods = mods, method = method, ...)
}
