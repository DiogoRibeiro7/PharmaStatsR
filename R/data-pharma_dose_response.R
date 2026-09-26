#' Simulated dose-response dataset
#'
#' A repeated-measures dataset generated from an Emax model for demonstrating
#' nonlinear and mixed-effects dose-response fits.
#'
#' @format A data frame with 30 rows and 3 variables:
#' \describe{
#'   \item{subject}{Subject identifier, with repeated doses per subject}
#'   \item{dose}{Dose level}
#'   \item{response}{Observed response}
#' }
#' @source Simulated data.
#' @examples
#' data(pharma_dose_response)
#' plot(pharma_dose_response$dose, pharma_dose_response$response)
pharma_dose_response <- local({
  set.seed(123)
  dose <- rep(c(0, 10, 20, 50, 100), each = 6)
  subject <- rep(seq_len(6), times = 5)
  subject_intercept <- rnorm(6, sd = 0.15)
  response <- 1 + subject_intercept[subject] +
    (4 * dose) / (20 + dose) + rnorm(length(dose), sd = 0.1)
  data.frame(subject = subject, dose = dose, response = response)
})
