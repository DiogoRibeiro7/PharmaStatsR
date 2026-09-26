#' Simulate a clinical trial dataset
#'
#' Generates a time-to-event dataset with staggered enrollment, flexible event
#' time distributions, and dropout. Events may follow exponential or Weibull
#' hazards that differ by arm.
#'
#' @param n integer number of subjects to simulate.
#' @param arms character vector of treatment arms.
#' @param accrual_period numeric study accrual period during which subjects enroll.
#' @param enroll_shape numeric shape parameter controlling enrollment over time.
#'   Values below 1 front-load enrollment; values above 1 back-load enrollment.
#' @param dropout_rate numeric hazard for dropout (per unit time).
#' @param hazard_control numeric event hazard in the control arm.
#' @param hazard_treatment numeric event hazard in the treatment arm.
#' @param event_dist character distribution for event times. Either "exponential" or
#'   "weibull".
#' @param event_shape numeric shape parameter for Weibull event times.
#' @param follow_up numeric total study duration from start to end of follow-up.
#'
#' @return A data.frame with subject id, treatment, enrollment time, observed
#'   time, event status, and dropout flag.
#' @export
#'
#' @examples
#' # Default exponential events with uniform accrual
#' sim <- pharma_trial_simulate(50)
#' head(sim)
#'
#' # Weibull events with back-loaded enrollment
#' sim2 <- pharma_trial_simulate(50, event_dist = "weibull", event_shape = 1.5,
#'                              enroll_shape = 2)
#' head(sim2)
#' Simulate enrollment times
#'
#' Generate subject enrollment times using a Beta distribution scaled to the
#' accrual period.
#'
#' @param n integer number of subjects.
#' @param accrual_period numeric total accrual duration.
#' @param shape numeric shape parameter controlling accrual pattern.
#' @return numeric vector of enrollment times.
#' @keywords internal
simulate_enrollment <- function(n, accrual_period, shape) {
  accrual_period * stats::rbeta(n, shape, 1)
}

#' Simulate event times
#'
#' Draw event times from exponential or Weibull distributions based on the
#' provided hazard and shape parameters.
#'
#' @param n integer number of subjects.
#' @param hazard numeric event hazard.
#' @param dist character distribution name ("exponential" or "weibull").
#' @param shape numeric shape parameter for Weibull events.
#' @return numeric vector of event times.
#' @keywords internal
simulate_events <- function(n, hazard, dist, shape) {
  if (dist == "exponential") {
    stats::rexp(n, rate = hazard)
  } else {
    stats::rweibull(n, shape = shape, scale = (1 / hazard)^(1 / shape))
  }
}

#' Simulate dropout times
#'
#' Generate dropout times from an exponential distribution with the specified
#' hazard rate.
#'
#' @param n integer number of subjects.
#' @param rate numeric dropout hazard.
#' @return numeric vector of dropout times.
#' @keywords internal
simulate_dropouts <- function(n, rate) {
  stats::rexp(n, rate = rate)
}

pharma_trial_simulate <- function(n, arms = c("control", "treatment"),
                                  accrual_period = 12,
                                  enroll_shape = 1,
                                  dropout_rate = 0.02,
                                  hazard_control = 0.1,
                                  hazard_treatment = 0.08,
                                  event_dist = c("exponential", "weibull"),
                                  event_shape = 1,
                                  follow_up = 24) {
  event_dist <- match.arg(event_dist)
  if (follow_up <= accrual_period) {
    stop("`follow_up` must be greater than `accrual_period`")
  }
  enroll_time <- simulate_enrollment(n, accrual_period, enroll_shape)
  arm <- sample(arms, n, replace = TRUE)
  haz <- ifelse(arm == arms[1], hazard_control, hazard_treatment)
  event_time <- simulate_events(n, haz, event_dist, event_shape)
  dropout_time <- simulate_dropouts(n, dropout_rate)
  available <- follow_up - enroll_time
  time <- pmin(event_time, dropout_time, available)
  status <- ifelse(time == event_time & event_time <= available, 1, 0)
  dropout <- ifelse(time == dropout_time & dropout_time < event_time &
    dropout_time < available, 1, 0)
  data.frame(
    id = seq_len(n), treatment = arm, enroll_time = enroll_time,
    time = time, status = status, dropout = dropout
  )
}
