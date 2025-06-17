#' Simulated dose-response dataset
#'
#' A dataset generated from an Emax model for demonstration of nonlinear dose-response fits.
#'
#' @format A data frame with 30 rows and 3 variables:
#' \describe{
#'   \item{subject}{Subject identifier}
#'   \item{dose}{Dose level}
#'   \item{response}{Observed response}
#' }
#' @source Simulated data.
pharma_dose_response <- local({
  set.seed(123)
  dose <- rep(c(0, 10, 20, 50, 100), each = 6)
  response <- 1 + (4 * dose) / (20 + dose) + rnorm(length(dose), sd = 0.2)
  data.frame(subject = seq_along(dose), dose = dose, response = response)
})
