# Independent derivation: docs/landmark-analysis.md. The twelve retained
# subjects deliberately reproduce the ordinary Cox reference risk sets.
# This file is self-contained; no target comes from another fitted model.
landmark_cox_reference_data <- function() {
  data.frame(
    time = c(6, 7, 7, 8, 10, 11, 6, 7, 8, 8, 9, 11,
             3, 4, 5, 5, 5.5, 105),
    status = c(1, 1, 0, 1, 0, 1, 0, 1, 1, 0, 1, 0,
               1, 0, 1, 0, 1, 0),
    exposure = c(rep(c(0, 1), each = 6), 0, 1, 0, 1, 1, 0),
    selected = c(rep(TRUE, 16), FALSE, FALSE),
    row.names = c(
      sprintf("subject-%02d", seq_len(12)),
      "before-event", "before-censor", "at-event", "at-censor",
      "excluded-event", "excluded-censor"
    )
  )
}

# Keep fitting choices literal: this reference concerns unweighted Breslow
# partial likelihood and model-based uncertainty, not robust covariance.
landmark_cox_reference_fit <- function(data, landmark = 5) {
  pharma_landmark_analysis(
    survival::Surv(time, status) ~ exposure,
    data = data, landmark = landmark, subset = selected,
    ties = "breslow", robust = FALSE, init = 0,
    model = TRUE, x = TRUE, y = TRUE
  )
}

# Analytic scalar expressions for this fixture, not a general Cox fitter.
landmark_cox_reference_terms <- function(beta) {
  stopifnot(is.numeric(beta), length(beta) == 1L, is.finite(beta))
  r <- exp(beta)
  list(
    loglik = 3 * beta - log(300) - 5 * log1p(r) - 2 * log(3 + 4 * r),
    score = 3 - 5 * r / (1 + r) - 8 * r / (3 + 4 * r),
    information = 5 * r / (1 + r)^2 + 24 * r / (3 + 4 * r)^2
  )
}

expect_landmark_cox_reference <- function(actual) {
  expected_beta <- log((sqrt(145) - 1) / 16)
  expected_variance <- 0.5857860744819957
  expected_loglik <- c(-13.0613386755665542, -12.9424910951151456)

  expect_s3_class(actual, "coxph")
  expect_identical(actual$method, "breslow")
  expect_equal(actual$n, 12)
  expect_equal(actual$nevent, 7)
  expect_null(actual$na.action)
  expect_null(actual$naive.var)
  expect_identical(names(stats::coef(actual)), "exposure")
  beta <- unname(stats::coef(actual))
  expect_equal(beta, expected_beta, tolerance = 1e-7)
  expect_equal(
    unname(stats::vcov(actual)), matrix(expected_variance, nrow = 1),
    tolerance = 1e-7
  )
  expect_equal(actual$loglik, expected_loglik, tolerance = 1e-9)
  result <- summary(actual)
  expect_equal(
    unname(result$coefficients["exposure", "se(coef)"]),
    0.7653666274942981, tolerance = 1e-7
  )
  expect_equal(
    unname(result$coefficients["exposure", "exp(coef)"]),
    (sqrt(145) - 1) / 16, tolerance = 1e-7
  )

  terms <- landmark_cox_reference_terms(beta)
  expect_lt(abs(terms$score), 1e-7)
  expect_equal(terms$information, 1 / expected_variance, tolerance = 1e-7)
  expect_equal(terms$loglik, actual$loglik[2], tolerance = 1e-9)
  expect_equal(
    landmark_cox_reference_terms(0)$loglik,
    expected_loglik[1], tolerance = 1e-12
  )
}

test_that("landmark eligibility retains explicit subjects and shifted times", {
  data <- landmark_cox_reference_data()
  actual <- landmark_cox_reference_fit(data)
  expected_ids <- sprintf("subject-%02d", seq_len(12))
  expected_times <- c(1, 2, 2, 3, 5, 6, 1, 2, 3, 3, 4, 6)
  expected_status <- c(1, 1, 0, 1, 0, 1, 0, 1, 1, 0, 1, 0)

  expect_landmark_cox_reference(actual)
  expect_identical(rownames(actual$model), expected_ids)
  expect_identical(rownames(actual$y), expected_ids)
  expect_identical(attr(actual$y, "type"), "right")
  expect_equal(unname(actual$y[, "time"]), expected_times, tolerance = 0)
  expect_equal(unname(actual$y[, "status"]), expected_status, tolerance = 0)
  expect_equal(unname(actual$x[, "exposure"]), rep(c(0, 1), each = 6))
})

test_that("the documented landmark risk sets reconstruct the likelihood", {
  data <- landmark_cox_reference_data()
  retained <- data[data$selected & data$time > 5, , drop = FALSE]
  retained$time <- retained$time - 5
  event_times <- c(1, 2, 3, 4, 6)
  risk_rows <- list(
    1:12, c(2:6, 8:12), c(4:6, 9:12), c(5, 6, 11, 12), c(6, 12)
  )
  expected_counts <- rbind(
    c(6, 6, 1, 0), c(5, 5, 1, 1), c(3, 4, 1, 1),
    c(2, 2, 0, 1), c(1, 1, 1, 0)
  )
  for (j in seq_along(event_times)) {
    at_risk <- retained$time >= event_times[j]
    event <- retained$time == event_times[j] & retained$status == 1
    expect_identical(
      rownames(retained)[at_risk],
      sprintf("subject-%02d", risk_rows[[j]])
    )
    expect_equal(
      c(sum(at_risk & retained$exposure == 0),
        sum(at_risk & retained$exposure == 1),
        sum(event & retained$exposure == 0),
        sum(event & retained$exposure == 1)),
      unname(expected_counts[j, ])
    )
  }
  # Rebuild the log likelihood from the tabulated risk counts at several
  # coefficients, including the closed-form score root, without coxph().
  for (beta in c(-1, 0, log((sqrt(145) - 1) / 16), 1)) {
    denominator <- expected_counts[, 1] + exp(beta) * expected_counts[, 2]
    loglik <- sum(expected_counts[, 4]) * beta -
      sum(rowSums(expected_counts[, 3:4]) * log(denominator))
    expect_equal(
      loglik, landmark_cox_reference_terms(beta)$loglik, tolerance = 1e-12
    )
  }
})

test_that("a common time translation preserves the landmark reference", {
  data <- landmark_cox_reference_data()
  original <- landmark_cox_reference_fit(data)
  data$time <- data$time + 100
  translated <- landmark_cox_reference_fit(data, landmark = 105)

  expect_landmark_cox_reference(translated)
  expect_identical(rownames(translated$model), rownames(original$model))
  expect_equal(translated$y, original$y, tolerance = 0)
  expect_equal(stats::coef(translated), stats::coef(original), tolerance = 1e-9)
  expect_equal(stats::vcov(translated), stats::vcov(original), tolerance = 1e-9)
  expect_equal(translated$loglik, original$loglik, tolerance = 1e-9)
})

test_that("original-row logical selection and row order retain the reference", {
  data <- landmark_cox_reference_data()
  rows <- data$selected
  actual <- pharma_landmark_analysis(
    survival::Surv(time, status) ~ exposure,
    data = data, landmark = 5, subset = rows,
    ties = "breslow", robust = FALSE, init = 0, model = TRUE
  )
  expect_landmark_cox_reference(actual)
  expect_identical(rownames(actual$model), sprintf("subject-%02d", seq_len(12)))

  data <- data[rev(seq_len(nrow(data))), , drop = FALSE]
  reordered <- landmark_cox_reference_fit(data)
  expect_landmark_cox_reference(reordered)
  expect_identical(rownames(reordered$model), sprintf("subject-%02d", 12:1))
})

test_that("missing predictors are allowed only outside the landmark risk set", {
  data <- landmark_cox_reference_data()
  data$exposure[13:18] <- NA_real_
  actual <- landmark_cox_reference_fit(data)
  expect_landmark_cox_reference(actual)
  expect_identical(rownames(actual$model), sprintf("subject-%02d", seq_len(12)))

  data$exposure[5] <- NA_real_
  expect_error(landmark_cox_reference_fit(data), "missing values")
})

test_that("complete follow-up is required before landmark eligibility", {
  # Missing follow-up cannot be dismissed as an ineligible observation.
  # Test an eligible row, a pre-landmark row, and an exact-landmark row.
  for (column in c("time", "status")) {
    for (row in c(1L, 13L, 15L)) {
      data <- landmark_cox_reference_data()
      data[row, column] <- NA_real_
      expect_error(landmark_cox_reference_fit(data), "missing values")
    }
  }
  # In contrast, original-row selection happens before response validation.
  data <- landmark_cox_reference_data()
  data$time[17] <- NA_real_
  data$status[18] <- NA_real_
  expect_landmark_cox_reference(landmark_cox_reference_fit(data))
})

test_that("empty landmark and subset populations fail before fitting", {
  data <- landmark_cox_reference_data()
  expect_error(
    landmark_cox_reference_fit(data, landmark = 11),
    "no observations remain after the landmark"
  )
  data$selected <- FALSE
  expect_error(
    landmark_cox_reference_fit(data), "no observations remain after the subset"
  )
})
