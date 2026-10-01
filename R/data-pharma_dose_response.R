#' Simulated dose-response dataset
#'
#' Six subjects observed once at each of five dose levels, generated with seed
#' 123 from an Emax mean, a subject-specific normal intercept (SD 0.15), and
#' independent normal observation noise (SD 0.1). The mean is
#' \eqn{1 + 4d/(20+d)} for dose \eqn{d}. No clinical units are assigned.
#'
#' @format A data frame with 30 rows and 3 variables:
#' \describe{
#'   \item{subject}{Integer subject identifier, 1 to 6}
#'   \item{dose}{Numeric dose level, 0, 10, 20, 50, or 100 (unitless)}
#'   \item{response}{Numeric simulated response (unitless)}
#' }
#' @source Generated in the package source with a fixed local RNG seed; no
#'   patient or experimental observations.
#' @details Useful for nonlinear Emax and repeated-subject examples. Subject
#'   IDs are numeric; convert them to factors when a model requires categorical
#'   subject effects. The five levels of \code{dose} are not two independent inputs
#'   for a response-surface model.
#' @examples
#' head(pharma_dose_response)
#' plot(pharma_dose_response$dose, pharma_dose_response$response)
pharma_dose_response <- .pharma_fixture_seed(123, function() {
  dose <- rep(c(0, 10, 20, 50, 100), each = 6)
  subject <- rep(seq_len(6), times = 5)
  subject_intercept <- rnorm(6, sd = 0.15)
  response <- 1 + subject_intercept[subject] +
    (4 * dose) / (20 + dose) + rnorm(length(dose), sd = 0.1)
  data.frame(subject = subject, dose = dose, response = response)
})
