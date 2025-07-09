#' Sample-size re-estimation
#'
#' Adjust sample size based on interim effect estimates.
#'
#' @param current_n Current total sample size.
#' @param effect Observed effect size at interim.
#' @param variance Estimate of variance.
#' @param target_power Desired power for final analysis.
#' @param alpha Significance level.
#'
#' @return New total sample size recommendation.
#' @export
#' @examples
#' pharma_sample_reestimate(50, 0.4, 1)
pharma_sample_reestimate <- function(current_n, effect, variance,
                                     target_power = 0.8, alpha = 0.05) {
  z_alpha <- qnorm(1 - alpha / 2)
  z_beta <- qnorm(target_power)
  n <- (z_alpha + z_beta)^2 * variance / effect^2
  ceiling(max(current_n, n))
}
