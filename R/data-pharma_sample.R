#' Example pharmaceutical dataset
#'
#' A small simulated dataset included for demonstrating the statistical
#' tests in PharmaStatsR.
#'
#' @format A data frame with 20 rows and 5 variables:
#' \describe{
#'   \item{subject}{Subject identifier}
#'   \item{treatment}{Treatment group ("A" or "B")}
#'   \item{dose}{Dose level (1 or 2)}
#'   \item{response}{Numeric response}
#'   \item{outcome}{Binary outcome}
#' }
#' @source Simulated data.
#' @examples
#' data(pharma_sample)
#' head(pharma_sample)
pharma_sample <- data.frame(
  subject = 1:20,
  treatment = rep(c("A", "B"), each = 10),
  dose = rep(c(1, 2), each = 10),
  response = c(5.1, 4.9, 5.5, 4.8, 5.3, 5.1, 5.7, 4.6, 5.2, 5.0,
               5.9, 6.1, 6.0, 5.8, 6.2, 5.7, 5.9, 6.3, 6.1, 6.2),
  outcome = c(0,1,1,0,1,0,1,0,1,0,
              1,0,0,1,0,1,0,1,0,1)
)
