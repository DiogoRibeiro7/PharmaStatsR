#' Single-arm beta-binomial posterior threshold check
#'
#' Compute the posterior probability that an unknown response rate exceeds a
#' fixed benchmark. This is a single-arm calculation; it does not compare
#' treatment and control groups or establish a calibrated stopping design.
#'
#' @param prior_alpha Positive scalar first shape of the beta prior.
#' @param prior_beta Positive scalar second shape of the beta prior.
#' @param successes Non-negative whole number of observed responses.
#' @param trials Positive whole number of observed participants; at least
#'   `successes`.
#' @param threshold Posterior probability cutoff, strictly between 0 and 1.
#'   The flag is `TRUE` only when the probability exceeds this cutoff.
#' @param null_rate Benchmark response probability, strictly between 0 and 1.
#'   Defaults to 0.5 for compatibility; set a clinically justified value.
#'
#' @return A list with `prob`, the posterior probability that the single-arm
#'   response rate is greater than `null_rate`, and `stop`, a logical flag
#'   for `prob > threshold`. The flag is a threshold check, not a
#'   recommendation to stop a study or a guarantee of error control.
#' @details
#' With a Beta(prior_alpha, prior_beta) prior, the posterior after observing
#' `successes` in `trials` is Beta(prior_alpha + successes,
#' prior_beta + trials - successes). Repeated looks require a pre-specified
#' schedule and calibration of operating characteristics.
#' @references
#' R documentation for the beta distribution:
#' \url{https://stat.ethz.ch/R-manual/R-devel/library/stats/html/Beta.html}
#' @export
#'
#' @examples
#' pharma_bayes_stopping(1, 1, successes = 8, trials = 10)
#' pharma_bayes_stopping(1, 1, successes = 8, trials = 10,
#'                       null_rate = 0.4, threshold = 0.9)
pharma_bayes_stopping <- function(prior_alpha, prior_beta, successes,
                                  trials, threshold = 0.95,
                                  null_rate = 0.5) {
  scalar_finite <- function(x) {
    is.numeric(x) && length(x) == 1L && is.finite(x)
  }
  if (!scalar_finite(prior_alpha) || prior_alpha <= 0) {
    stop("`prior_alpha` must be a finite positive beta shape", call. = FALSE)
  }
  if (!scalar_finite(prior_beta) || prior_beta <= 0) {
    stop("`prior_beta` must be a finite positive beta shape", call. = FALSE)
  }
  if (!scalar_finite(trials) || trials < 1 || trials %% 1 != 0 ||
      trials > .Machine$integer.max) {
    stop("`trials` must be a positive whole number within the supported range",
         call. = FALSE)
  }
  if (!scalar_finite(successes) || successes < 0 || successes %% 1 != 0) {
    stop("`successes` must be a non-negative whole number", call. = FALSE)
  }
  if (successes > trials) {
    stop("`successes` cannot exceed `trials`", call. = FALSE)
  }
  if (!scalar_finite(threshold) || threshold <= 0 || threshold >= 1) {
    stop("`threshold` must be strictly between 0 and 1", call. = FALSE)
  }
  if (!scalar_finite(null_rate) || null_rate <= 0 || null_rate >= 1) {
    stop("`null_rate` must be strictly between 0 and 1", call. = FALSE)
  }

  post_alpha <- prior_alpha + successes
  post_beta <- prior_beta + (trials - successes)
  # Beta symmetry computes the upper tail without subtracting from one.
  prob <- stats::pbeta(1 - null_rate, post_beta, post_alpha)
  list(prob = prob, stop = prob > threshold)
}
