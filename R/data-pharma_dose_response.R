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
#' @source Responses generated with seed 123 by
#'   \code{data-raw/generate-fixture-responses.R} and stored as fixed values in
#'   the package source; no patient or experimental observations.
#' @details Useful for nonlinear Emax and repeated-subject examples. Subject
#'   IDs are numeric; convert them to factors when a model requires categorical
#'   subject effects. Dose is a single continuous input with five ordered
#'   levels; these data do not support a multivariate response surface.
#' @examples
#' head(pharma_dose_response)
#' plot(pharma_dose_response$dose, pharma_dose_response$response)
pharma_dose_response <- data.frame(
  subject = rep(seq_len(6), times = 5),
  dose = rep(c(0, 10, 20, 50, 100), each = 6),
  response = c(
    0.962020273616088, 0.838967253116855, 1.16512096193302,
    0.966010061703691, 1.14180134001809, 1.29324113073823,
    2.28933913140991, 2.30987498150535, 2.51155546698029,
    2.52260090572733, 2.4025115414304, 2.39393136570286,
    2.98606424317354, 2.91819423580471, 3.12702387652368,
    2.98877876724786, 2.91679271544342, 3.18437062510338,
    3.7105675833751, 3.65394690264612, 4.17472780871468,
    3.8830564276402, 3.7627223237158, 4.23978409728234,
    4.29190840849818, 4.26929956161161, 4.6566521465602,
    4.43172294080032, 4.43488460177122, 4.65945710677583
  )
)
