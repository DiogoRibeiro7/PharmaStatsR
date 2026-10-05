# Independent derivation and fixed targets: docs/cox-timevarying.md.
# Six subjects supply eight (start, stop] intervals and five events.
# Interval rows are not eight independent subjects.
counting_cox_reference_data <- function() {
  data.frame(
    id = c("A", "B", "B", "C", "D", "E", "E", "F"),
    start = c(0, 0, 2, 0, 0, 0, 4, 2),
    stop = c(2, 2, 4, 3, 5, 4, 6, 7),
    event = c(1, 0, 1, 1, 1, 0, 1, 0),
    exposure = c(1, 0, 1, 0, 0, 1, 0, 1),
    selected = TRUE,
    row.names = c("A1", "B1", "B2", "C1", "D1", "E1", "E2", "F1"),
    stringsAsFactors = FALSE
  )
}

# Analytic likelihood and derivatives for this fixture, not a Cox fitter.
counting_cox_reference_terms <- function(beta) {
  stopifnot(is.numeric(beta), length(beta) == 1L, is.finite(beta))
  r <- exp(beta)
  list(
    loglik = 2 * beta - log(3 + 2 * r) - log(2 + 3 * r) -
      log(1 + 3 * r) - log(2 + r) - log1p(r),
    score = 2 - 2 * r / (3 + 2 * r) - 3 * r / (2 + 3 * r) -
      3 * r / (1 + 3 * r) - r / (2 + r) - r / (1 + r),
    information = 6 * r / (3 + 2 * r)^2 + 6 * r / (2 + 3 * r)^2 +
      3 * r / (1 + 3 * r)^2 + 2 * r / (2 + r)^2 + r / (1 + r)^2
  )
}

fit_counting_cox_reference <- function(data) {
  stopifnot(is.data.frame(data))
  pharma_cox_timevarying(
    survival::Surv(start, stop, event) ~ exposure, data,
    ties = "breslow", robust = FALSE, init = 0,
    model = TRUE, x = TRUE, y = TRUE
  )
}

expect_counting_cox_reference <- function(actual, data) {
  # Fixed targets were calculated at 80-digit precision from the risk table,
  # without coxph(). Model-based variance is inverse observed information.
  beta <- -0.5181598058136135
  variance <- 0.9145168032707050
  se <- 0.9563037191555333
  information <- 1.0934736206306656
  loglik <- c(-6.3969296552161464, -6.2468419093423460)

  expect_s3_class(actual, "coxph")
  expect_identical(actual$method, "breslow")
  expect_null(actual$naive.var)
  expect_equal(actual$n, nrow(data))
  expect_equal(actual$nevent, 5)
  expect_identical(rownames(actual$model), rownames(data))
  expect_identical(rownames(actual$y), rownames(data))
  expect_identical(attr(actual$y, "type"), "counting")
  expect_equal(unname(actual$y[, "start"]), data$start)
  expect_equal(unname(actual$y[, "stop"]), data$stop)
  expect_equal(unname(actual$y[, "status"]), data$event)
  expect_equal(unname(actual$x[, "exposure"]), data$exposure)
  retained_ids <- data$id[match(rownames(actual$model), rownames(data))]
  expect_setequal(retained_ids, LETTERS[1:6])
  expect_equal(length(unique(retained_ids)), 6)
  expect_true(all(tapply(data$event, retained_ids, sum) <= 1))

  expect_identical(names(stats::coef(actual)), "exposure")
  fitted_beta <- unname(stats::coef(actual))
  expect_equal(fitted_beta, beta, tolerance = 1e-7)
  expect_equal(
    unname(stats::vcov(actual)), matrix(variance, nrow = 1),
    tolerance = 1e-7
  )
  expect_equal(
    unname(summary(actual)$coefficients["exposure", "se(coef)"]),
    se, tolerance = 1e-7
  )
  expect_equal(exp(fitted_beta), 0.5956155884608161, tolerance = 1e-7)
  expect_equal(actual$loglik, loglik, tolerance = 1e-9)
  terms <- counting_cox_reference_terms(fitted_beta)
  expect_lt(abs(terms$score), 1e-7)
  expect_equal(terms$information, information, tolerance = 1e-7)
  expect_equal(actual$loglik[2], terms$loglik, tolerance = 1e-9)
  expect_equal(counting_cox_reference_terms(0)$loglik, -log(600),
    tolerance = 1e-12
  )
  expect_equal(counting_cox_reference_terms(0)$score, -7 / 12,
    tolerance = 1e-12
  )
}

test_that("counting-process Cox matches independent interval risk sets", {
  data <- counting_cox_reference_data()
  actual <- fit_counting_cox_reference(data)
  expect_counting_cox_reference(actual, data)

  # Endpoint membership is explicit: at t=2 B1 applies and F has not entered;
  # at t=4 E1 still applies, even though E's next row has a different value.
  event_times <- c(2, 3, 4, 5, 6)
  risk_rows <- list(
    c("A1", "B1", "C1", "D1", "E1"),
    c("B2", "C1", "D1", "E1", "F1"),
    c("B2", "D1", "E1", "F1"),
    c("D1", "E2", "F1"),
    c("E2", "F1")
  )
  n_zero <- c(3, 2, 1, 2, 1)
  n_one <- c(2, 3, 3, 1, 1)
  event_exposure <- c(1, 0, 1, 0, 0)
  for (j in seq_along(event_times)) {
    time <- event_times[j]
    at_risk <- actual$y[, "start"] < time & time <= actual$y[, "stop"]
    observed <- actual$y[, "stop"] == time & actual$y[, "status"] == 1
    expect_setequal(rownames(actual$y)[at_risk], risk_rows[[j]])
    expect_equal(sum(actual$x[at_risk, "exposure"] == 0), n_zero[j])
    expect_equal(sum(actual$x[at_risk, "exposure"] == 1), n_one[j])
    expect_equal(sum(observed), 1)
    expect_equal(unname(actual$x[observed, "exposure"]), event_exposure[j])
    ids <- data$id[match(rownames(actual$y)[at_risk], rownames(data))]
    expect_false(anyDuplicated(ids) > 0L)
  }
})

test_that("original-row selection preserves the independent counting reference", {
  reference <- counting_cox_reference_data()
  extra <- reference[c(1, 3, 4), , drop = FALSE]
  extra$id <- c("G", "H", "I")
  extra$start <- c(0, 0, 0)
  extra$stop <- c(1, 9, 2)
  extra$event <- c(1, 0, 0)
  extra$exposure <- c(0, 1, NA_real_)
  extra$selected <- FALSE
  rownames(extra) <- c("excluded-event", "excluded-entry", "excluded-missing")
  data <- rbind(reference, extra)
  actual <- pharma_cox_timevarying(
    survival::Surv(start, stop, event) ~ exposure, data,
    subset = selected, ties = "breslow", robust = FALSE, init = 0,
    model = TRUE, x = TRUE, y = TRUE
  )
  expect_counting_cox_reference(actual, reference)
})

test_that("splitting an unchanged interval at an event preserves the reference", {
  data <- counting_cox_reference_data()
  before <- after <- data["D1", , drop = FALSE]
  before$stop <- 2
  before$event <- 0
  after$start <- 2
  rownames(before) <- "D1a"
  rownames(after) <- "D1b"
  split <- rbind(data[1:4, ], before, after, data[6:8, ])
  actual <- fit_counting_cox_reference(split)
  expect_counting_cox_reference(actual, split)
  expect_equal(actual$n, 9)
  # Only the first D interval is at risk for the event at the split time.
  at_two <- actual$y[, "start"] < 2 & 2 <= actual$y[, "stop"]
  expect_true("D1a" %in% rownames(actual$y)[at_two])
  expect_false("D1b" %in% rownames(actual$y)[at_two])
  expect_equal(sum(at_two), 5)
})

test_that("interval row order preserves the independent counting reference", {
  data <- counting_cox_reference_data()
  data <- data[rev(seq_len(nrow(data))), , drop = FALSE]
  expect_counting_cox_reference(fit_counting_cox_reference(data), data)
})

test_that("counting-process checks do not silently drop selected intervals", {
  data <- counting_cox_reference_data()
  bad <- data
  bad$exposure[1] <- NA_real_
  expect_error(
    pharma_cox_timevarying(
      survival::Surv(start, stop, event) ~ exposure, bad,
      na.action = stats::na.omit, ties = "breslow", robust = FALSE
    ),
    "model variables must be complete"
  )
  # Missing weights are outside the prechecked formula. If the backend drops
  # that row, the wrapper must reject the changed analysis population.
  expect_error(
    pharma_cox_timevarying(
      survival::Surv(start, stop, event) ~ exposure, data,
      weights = c(1, 1, 1, 1, NA_real_, 1, 1, 1),
      na.action = stats::na.omit, ties = "breslow", robust = FALSE
    ),
    "changed the selected analysis rows"
  )
})
