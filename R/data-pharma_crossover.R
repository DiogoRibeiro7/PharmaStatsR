#' De-identified crossover trial dataset
#'
#' A simulated dataset representing a two-period crossover study.
#'
#' @format A data frame with 20 rows and 5 variables:
#' \describe{
#'   \item{subject}{Subject identifier}
#'   \item{period}{Study period (1 or 2)}
#'   \item{treatment}{Treatment received ("A" or "B")}
#'   \item{response}{Numeric response}
#'   \item{outcome}{Binary outcome}
#' }
#' @source Simulated data.
#' @examples
#' data(pharma_crossover)
#' head(pharma_crossover)
pharma_crossover <- data.frame(
  subject = rep(1:10, each = 2),
  period = rep(1:2, times = 10),
  treatment = rep(c("A", "B"), each = 10),
  response = c(5.2,5.0,5.3,5.1,4.9,5.4,5.0,4.8,5.5,5.2,
               5.4,5.6,5.7,5.5,5.8,5.6,5.9,5.7,6.0,5.8),
  outcome = c(1,0,1,0,0,1,0,0,1,0,
             1,0,1,0,1,0,1,0,1,0)
)
