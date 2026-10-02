#' Simulated survival dataset
#'
#' Hand-entered illustrative follow-up and status values for 30 unique
#' subjects, with 15 in each treatment group. These are not clinical records.
#'
#' @description Simulated survival dataset used to illustrate survival
#' functions in PharmaStatsR.
#'
#' @format A data frame with 30 rows and 4 variables:
#' \describe{
#'   \item{subject}{Integer subject identifier, 1 to 30}
#'   \item{time}{Positive numeric follow-up time (unitless)}
#'   \item{status}{Numeric status, 1 = unspecified example event, 0 = censored}
#'   \item{treatment}{Character group label, A or B}
#' }
#' @source Hand-entered illustrative values in the package source.
#' @details Use for time-to-event examples with right censoring. No time unit,
#'   event definition, or treatment effect is specified by this fixture.
#' @docType data
#' @keywords datasets
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
