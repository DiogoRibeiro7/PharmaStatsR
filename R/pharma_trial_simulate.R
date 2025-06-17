#' Simulate a clinical trial dataset
#'
#' Generates a simple time-to-event dataset with randomization, event times,
#' and dropout. Events follow exponential hazards that may differ by arm.
#'
#' @param n Number of subjects to simulate.
#' @param arms Character vector of treatment arms.
#' @param dropout_rate Hazard for dropout (per unit time).
#' @param hazard_control Event hazard in the control arm.
#' @param hazard_treatment Event hazard in the treatment arm.
#' @param follow_up Follow-up time for censoring.
#'
#' @return A data.frame with subject id, treatment, time, status, and dropout flag.
#' @export
#'
#' @examples
#' sim <- pharma_trial_simulate(50)
#' head(sim)
pharma_trial_simulate <- function(n, arms = c("control", "treatment"),
                                  dropout_rate = 0.02,
                                  hazard_control = 0.1,
                                  hazard_treatment = 0.08,
                                  follow_up = 12) {
  arm <- sample(arms, n, replace = TRUE)
  haz <- ifelse(arm == arms[1], hazard_control, hazard_treatment)
  event_time <- stats::rexp(n, rate = haz)
  dropout_time <- stats::rexp(n, rate = dropout_rate)
  time <- pmin(event_time, dropout_time, follow_up)
  status <- ifelse(time == event_time & event_time <= follow_up, 1, 0)
  dropout <- ifelse(time == dropout_time & dropout_time < event_time & dropout_time < follow_up, 1, 0)
  data.frame(id = seq_len(n), treatment = arm, time = time, status = status, dropout = dropout)
}
