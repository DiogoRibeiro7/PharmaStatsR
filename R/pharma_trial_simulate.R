#' Simulate a clinical trial dataset
#'
#' Generates a time-to-event dataset with staggered enrollment, flexible event
#' time distributions, and dropout. Events may follow exponential or Weibull
#' hazards that differ by arm.
#'
#' @param n Number of subjects to simulate.
#' @param arms Character vector of treatment arms.
#' @param accrual_period Study accrual period during which subjects enroll.
#' @param enroll_shape Shape parameter controlling enrollment over time. Values
#'   < 1 front-load enrollment, > 1 back-load enrollment.
#' @param dropout_rate Hazard for dropout (per unit time).
#' @param hazard_control Event hazard in the control arm.
#' @param hazard_treatment Event hazard in the treatment arm.
#' @param event_dist Distribution for event times. Either "exponential" or
#'   "weibull".
#' @param event_shape Shape parameter for Weibull event times.
#' @param follow_up Total study duration from start to end of follow-up.
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
simulate_enrollment <- function(n, accrual_period, shape) {
  accrual_period * stats::rbeta(n, shape, 1)
}

simulate_events <- function(n, hazard, dist, shape) {
  if (dist == "exponential") {
    stats::rexp(n, rate = hazard)
  } else {
    stats::rweibull(n, shape = shape, scale = (1 / hazard)^(1 / shape))
  }
}

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
  data.frame(id = seq_len(n), treatment = arm, enroll_time = enroll_time,
             time = time, status = status, dropout = dropout)
}
