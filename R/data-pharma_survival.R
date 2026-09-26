#' Simulated survival dataset
#'
#' A small time-to-event dataset for demonstrating survival analysis.
#'
#' @description Simulated survival dataset used to illustrate survival
#' functions in PharmaStatsR.
#'
#' @format A data frame with 30 rows and 4 variables:
#' \describe{
#'   \item{subject}{Subject identifier}
#'   \item{time}{Follow-up time}
#'   \item{status}{Event indicator (1 = event, 0 = censored)}
#'   \item{treatment}{Treatment group}
#' }
#' @source Simulated data.
#' @examples
#' summary(pharma_survival)
#' @export
pharma_survival <- data.frame(
  subject = 1:30,
  time = c(5,6,4,3,10,9,8,6,7,5,
           12,11,13,10,9,8,14,13,12,11,
           15,16,14,13,17,18,16,15,14,19),
  status = c(1,1,1,0,1,0,1,1,0,1,
             1,0,1,1,0,1,1,0,1,1,
             0,1,1,0,1,0,1,0,1,1),
  treatment = rep(c("A","B"), each = 15)
)
