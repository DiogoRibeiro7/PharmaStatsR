#' Simulate two-arm time-to-event trial data
#'
#' Randomize subjects equally between two arms, draw enrollment times from a
#' scaled Beta distribution, and independently draw event and dropout times.
#' Follow-up ends at a fixed study time measured from the start of accrual.
#'
#' @param n Positive whole number of subjects.
#' @param arms Two distinct, nonempty character labels, in control and treatment
#'   order. Assignment is independent with probability 1/2 for each arm; exact
#'   balance is not guaranteed.
#' @param accrual_period Nonnegative duration of accrual in the same time units
#'   as the other times. Zero enrolls everyone at time zero.
#' @param enroll_shape Positive shape of the Beta(enroll_shape, 1) enrollment
#'   fraction. Values below 1 front-load accrual; values above 1 back-load it.
#' @param dropout_rate Nonnegative constant dropout hazard per unit time.
#'   Zero disables dropout.
#' @param hazard_control,hazard_treatment Nonnegative event parameters for the
#'   respective arms. For exponential events these are constant hazards; for
#'   Weibull events each is the coefficient lambda in cumulative hazard
#'   H(t) = lambda * t^event_shape. Zero disables events in that arm.
#' @param event_dist Event-time distribution: "exponential" or "weibull".
#' @param event_shape Positive Weibull shape; ignored for exponential draws.
#'   A Weibull shape of 1 has an exponential survival distribution.
#' @param follow_up Fixed study end time since the start of accrual; must be
#'   greater than accrual_period.
#'
#' @return A data frame with id, treatment, enroll_time (since study start),
#'   time (observed duration since enrollment), status (1 for event, 0 otherwise),
#'   and dropout (1 for dropout, 0 otherwise). A row with both indicators zero
#'   is administratively censored. Events take precedence over exact ties.
#' @export
#'
#' @examples
#' set.seed(42)
#' sim <- pharma_trial_simulate(50)
#' head(sim)
#'
#' sim2 <- pharma_trial_simulate(50, event_dist = "weibull", event_shape = 1.5,
#'                              enroll_shape = 2)
#' head(sim2)
pharma_trial_simulate <- function(n, arms = c("control", "treatment"),
                                  accrual_period = 12,
                                  enroll_shape = 1,
                                  dropout_rate = 0.02,
                                  hazard_control = 0.1,
                                  hazard_treatment = 0.08,
                                  event_dist = c("exponential", "weibull"),
                                  event_shape = 1,
                                  follow_up = 24) {
  scalar_number <- function(x) {
    is.numeric(x) && length(x) == 1L && !is.na(x) && is.finite(x)
  }
  if (!scalar_number(n) || n < 1 || n != floor(n) ||
      n > .Machine$integer.max) {
    stop("`n` must be a positive whole number", call. = FALSE)
  }
  if (!is.character(arms) || length(arms) != 2L ||
      anyNA(arms) || any(!nzchar(trimws(arms))) || arms[1] == arms[2]) {
    stop("`arms` must contain two distinct nonempty character labels", call. = FALSE)
  }
  for (name in c("accrual_period", "enroll_shape", "dropout_rate",
                 "hazard_control", "hazard_treatment", "event_shape", "follow_up")) {
    value <- get(name, inherits = FALSE)
    if (!scalar_number(value) ||
        (name %in% c("enroll_shape", "event_shape", "follow_up") && value <= 0) ||
        (name %in% c("accrual_period", "dropout_rate",
                     "hazard_control", "hazard_treatment") && value < 0)) {
      stop(sprintf("`%s` must be a finite %s number",
                   name, if (name %in% c("enroll_shape", "event_shape", "follow_up"))
                     "positive" else "nonnegative"), call. = FALSE)
    }
  }
  event_dist <- match.arg(event_dist)
  if (follow_up <= accrual_period) {
    stop("`follow_up` must be greater than `accrual_period`", call. = FALSE)
  }
  enroll_time <- simulate_enrollment(n, accrual_period, enroll_shape)
  arm <- sample(arms, n, replace = TRUE)
  haz <- ifelse(arm == arms[1], hazard_control, hazard_treatment)
  event_time <- simulate_events(n, haz, event_dist, event_shape)
  dropout_time <- simulate_dropouts(n, dropout_rate)
  available <- follow_up - enroll_time
  time <- pmin(event_time, dropout_time, available)
  status <- as.integer(time == event_time & event_time <= available)
  dropout <- as.integer(time == dropout_time & dropout_time < event_time &
    dropout_time < available)
  data.frame(
    id = seq_len(n), treatment = arm, enroll_time = enroll_time,
    time = time, status = status, dropout = dropout
  )
}

# Enrollment from Beta(shape, 1), scaled to the accrual period.
simulate_enrollment <- function(n, accrual_period, shape) {
  accrual_period * stats::rbeta(n, shape, 1)
}

# Zero event parameters represent subjects who cannot have an event.
simulate_events <- function(n, hazard, dist, shape) {
  times <- rep(Inf, n)
  active <- hazard > 0
  if (any(active)) {
    if (dist == "exponential") {
      times[active] <- stats::rexp(sum(active), rate = hazard[active])
    } else {
      times[active] <- stats::rweibull(
        sum(active), shape = shape, scale = hazard[active]^(-1 / shape)
      )
    }
  }
  times
}

# Zero dropout rate represents no dropout.
simulate_dropouts <- function(n, rate) {
  if (rate == 0) {
    return(rep(Inf, n))
  }
  stats::rexp(n, rate = rate)
}
