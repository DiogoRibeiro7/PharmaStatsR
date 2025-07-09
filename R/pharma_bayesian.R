#' Bayesian GLM with rstanarm
#'
#' Fit a generalized linear model using MCMC via `rstanarm::stan_glm`.
#'
#' @param formula Model formula
#' @param data Data frame
#' @param ... Additional arguments passed to [rstanarm::stan_glm]
#'
#' @return A `stanreg` object
#' @export
#' @examples
#' \dontrun{
#'   fit <- pharma_bayesian_glm(outcome ~ dose, data = pharma_sample, iter = 500)
#' }
pharma_bayesian_glm <- function(formula, data, ...) {
  if (!requireNamespace("rstanarm", quietly = TRUE)) {
    stop("Package 'rstanarm' is required for pharma_bayesian_glm()")
  }
  rstanarm::stan_glm(formula = formula, data = data, ...)
}

#' Posterior summary with credible intervals
#'
#' Provide summary statistics including credible intervals for a fitted
#' Bayesian model.
#'
#' @param model A `stanreg` object from [rstanarm::stan_glm]
#' @param prob Width of the credible interval (default 0.95)
#'
#' @return Summary object
#' @export
#' @examples
#' \dontrun{
#'   fit <- pharma_bayesian_glm(outcome ~ dose, data = pharma_sample, iter = 500)
#'   pharma_posterior_summary(fit)
#' }
pharma_posterior_summary <- function(model, prob = 0.95) {
  if (!requireNamespace("rstanarm", quietly = TRUE)) {
    stop("Package 'rstanarm' is required for pharma_posterior_summary()")
  }
  ci <- c((1 - prob) / 2, 1 - (1 - prob) / 2)
  summary(model, probs = ci)
}

#' Posterior predictive check
#'
#' Generate a posterior predictive check plot for a fitted Bayesian model
#' using [bayesplot::pp_check].
#'
#' @param model A `stanreg` object
#' @param ... Additional arguments passed to [bayesplot::pp_check]
#'
#' @return A `ggplot` object
#' @export
#' @examples
#' \dontrun{
#'   fit <- pharma_bayesian_glm(outcome ~ dose, data = pharma_sample, iter = 500)
#'   pharma_pp_check(fit)
#' }
pharma_pp_check <- function(model, ...) {
  if (!requireNamespace("bayesplot", quietly = TRUE)) {
    stop("Package 'bayesplot' is required for pharma_pp_check()")
  }
  bayesplot::pp_check(model, ...)
}
