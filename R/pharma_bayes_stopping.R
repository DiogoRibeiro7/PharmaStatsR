#' Bayesian adaptive stopping rule
#'
#' Compute the posterior probability that the treatment effect is positive
#' and stop early if it exceeds a threshold.
#'
#' @param prior_alpha,prior_beta Prior parameters for beta prior.
#' @param successes Number of successes observed.
#' @param trials Number of trials.
#' @param threshold Probability threshold to stop the trial.
#'
#' @return Posterior probability of success.
#' @export
pharma_bayes_stopping <- function(prior_alpha, prior_beta, successes,
                                  trials, threshold = 0.95) {
  post_alpha <- prior_alpha + successes
  post_beta <- prior_beta + trials - successes
  prob <- 1 - pbeta(0.5, post_alpha, post_beta)
  list(prob = prob, stop = prob > threshold)
}
