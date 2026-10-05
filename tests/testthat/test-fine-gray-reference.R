# Independent no-censoring derivation: docs/competing-risks.md.
# Expected values come from explicit subdistribution risk sets, not crr().
fine_gray_reference_data <- function() {
  data.frame(
    time = seq_len(8),
    status = c(2, 1, 1, 2, 1, 1, 2, 1),
    exposure = c(1, 0, 1, 0, 0, 1, 1, 0),
    row.names = sprintf("subject-%02d", seq_len(8))
  )
}

# Fix the optimizer and variance-output options for this small fixture.
# Requesting variance output supplies inf/invinf; var is NOT validated here.
fine_gray_reference_fit <- function(data, failcode = 1, cencode = 0) {
  pharma_competing_risks(
    survival::Surv(time, status) ~ exposure, data,
    failcode = failcode, cencode = cencode,
    init = 0, gtol = 1e-10, maxiter = 50, variance = TRUE
  )
}

# Analytic expressions for this fixture only, not a general Fine-Gray fitter.
fine_gray_reference_terms <- function(beta) {
  stopifnot(is.numeric(beta), length(beta) == 1L, is.finite(beta))
  r <- exp(beta)
  list(
    loglik = 2 * beta - log(24) - 3 * log1p(r) -
      log(3 + 4 * r) - log(2 + 3 * r),
    score = 2 - 3 * r / (1 + r) - 4 * r / (3 + 4 * r) -
      3 * r / (2 + 3 * r),
    information = 3 * r / (1 + r)^2 + 12 * r / (3 + 4 * r)^2 +
      6 * r / (2 + 3 * r)^2,
    jumps = 1 / (c(4, 3, 3, 2, 2) + r * c(4, 4, 3, 3, 2))
  )
}

expect_fine_gray_reference <- function(actual) {
  expected_beta <- -0.5469066020605744
  expected_information <- 1.1911997895342392
  expected_jumps <- c(
    0.1583544004247850, 0.1881485514861691, 0.2111392005663800,
    0.2676507702220366, 0.3167088008495699
  )
  expect_s3_class(actual, "crr")
  expect_true(actual$converged)
  expect_equal(actual$n, 8)
  expect_equal(actual$n.missing, 0)
  expect_identical(names(actual$coef), "exposure")
  beta <- unname(actual$coef)
  expect_equal(beta, expected_beta, tolerance = 1e-7)
  expect_equal(exp(beta), 0.5787373090319948, tolerance = 1e-7)
  expect_equal(actual$loglik.null, -8.8128434335171952, tolerance = 1e-12)
  expect_equal(actual$loglik, -8.6303388076825458, tolerance = 1e-9)
  expect_equal(
    unname(actual$inf), matrix(expected_information, nrow = 1),
    tolerance = 1e-7
  )
  # Inverse information is not the separately estimated coefficient covariance.
  expect_equal(
    unname(actual$invinf), matrix(0.8394897386533299, nrow = 1),
    tolerance = 1e-7
  )
  expect_equal(actual$uftime, c(2, 3, 5, 6, 8), tolerance = 0)
  expect_equal(actual$bfitj, expected_jumps, tolerance = 1e-7)
  expect_lt(abs(as.numeric(actual$score)), 1e-7)

  terms <- fine_gray_reference_terms(beta)
  expect_lt(abs(terms$score), 1e-7)
  expect_equal(as.numeric(actual$score), terms$score, tolerance = 1e-9)
  expect_equal(as.numeric(actual$inf), terms$information, tolerance = 1e-9)
  expect_equal(actual$loglik, terms$loglik, tolerance = 1e-9)
  expect_equal(actual$bfitj, terms$jumps, tolerance = 1e-9)
}

test_that("the no-censoring risk table retains earlier competing events", {
  data <- fine_gray_reference_data()
  event_times <- c(2, 3, 5, 6, 8)
  risk_rows <- list(
    1:8, c(1, 3:8), c(1, 4:8), c(1, 4, 6:8), c(1, 4, 7, 8)
  )
  expected_counts <- rbind(c(4, 4), c(3, 4), c(3, 3), c(2, 3), c(2, 2))
  event_exposure <- c(0, 1, 0, 1, 0)
  expect_equal(sum(data$status == 1), 5)
  expect_equal(sum(data$status == 2), 3)
  expect_false(any(data$status == 0))
  expect_identical(anyDuplicated(data$time), 0L)
  expect_equal(data$time[data$status == 1], event_times, tolerance = 0)

  for (j in seq_along(event_times)) {
    # With no censoring, all retained subdistribution weights equal one.
    at_risk <- data$time >= event_times[j] |
      (data$time < event_times[j] & data$status == 2)
    event <- data$time == event_times[j] & data$status == 1
    expect_identical(
      rownames(data)[at_risk], sprintf("subject-%02d", risk_rows[[j]])
    )
    expect_equal(
      c(sum(at_risk & data$exposure == 0), sum(at_risk & data$exposure == 1)),
      unname(expected_counts[j, ])
    )
    expect_equal(data$exposure[event], event_exposure[j])
  }

  # Independently reconstruct the analytic likelihood and derivatives from
  # the fixed table, including values away from the fitted score root.
  for (beta in c(-1, 0, -0.5469066020605744, 1)) {
    denominator <- expected_counts[, 1] + exp(beta) * expected_counts[, 2]
    probability <- exp(beta) * expected_counts[, 2] / denominator
    terms <- fine_gray_reference_terms(beta)
    expect_equal(
      sum(event_exposure) * beta - sum(log(denominator)),
      terms$loglik, tolerance = 1e-12
    )
    expect_equal(sum(event_exposure - probability), terms$score,
      tolerance = 1e-12
    )
    expect_equal(sum(probability * (1 - probability)), terms$information,
      tolerance = 1e-12
    )
    expect_equal(1 / denominator, terms$jumps, tolerance = 1e-12)
  }

  # Dropping earlier competing events instead gives cause-specific risk sets.
  # At the correct Fine-Gray root that incorrect score is about 0.428, not zero.
  beta <- -0.5469066020605744
  wrong_score <- 0
  for (j in seq_along(event_times)) {
    x <- data$exposure[data$time >= event_times[j]]
    weights <- exp(beta * x)
    wrong_score <- wrong_score + event_exposure[j] - sum(weights * x) / sum(weights)
  }
  expect_gt(abs(wrong_score), 0.1)
})

test_that("Fine-Gray output matches the independent no-censoring reference", {
  skip_if_not_installed("cmprsk")
  expect_fine_gray_reference(fine_gray_reference_fit(fine_gray_reference_data()))
})

test_that("Fine-Gray derivatives and hazard jumps match the zero-coefficient table", {
  skip_if_not_installed("cmprsk")
  actual <- pharma_competing_risks(
    survival::Surv(time, status) ~ exposure, fine_gray_reference_data(),
    init = 0, maxiter = 0, variance = TRUE
  )
  # maxiter = 0 requests evaluation, not a converged fitted model.
  expect_equal(unname(actual$coef), 0, tolerance = 0)
  expect_equal(actual$loglik, -log(6720), tolerance = 1e-12)
  expect_equal(as.numeric(actual$score), -47 / 70, tolerance = 1e-12)
  expect_equal(as.numeric(actual$inf), 6051 / 4900, tolerance = 1e-12)
  expect_equal(actual$bfitj, 1 / c(8, 7, 6, 5, 4), tolerance = 1e-12)
})

test_that("explicit event-code relabelling preserves the Fine-Gray reference", {
  skip_if_not_installed("cmprsk")
  # (target, competing, censoring): arbitrary codes and swapped 1/2 codes.
  for (codes in list(c(11, 7, -1), c(2, 1, 9))) {
    data <- fine_gray_reference_data()
    data$status <- ifelse(data$status == 1, codes[1], codes[2])
    actual <- fine_gray_reference_fit(data, failcode = codes[1], cencode = codes[3])
    expect_fine_gray_reference(actual)
  }
})

test_that("row permutations preserve the Fine-Gray numerical reference", {
  skip_if_not_installed("cmprsk")
  data <- fine_gray_reference_data()
  for (rows in list(8:1, c(2, 4, 6, 8, 1, 3, 5, 7))) {
    expect_fine_gray_reference(fine_gray_reference_fit(data[rows, , drop = FALSE]))
  }
})

test_that("an absent target event fails before the Fine-Gray optimizer", {
  skip_if_not_installed("cmprsk")
  data <- fine_gray_reference_data()
  data$status <- 2
  expect_error(fine_gray_reference_fit(data), "failcode must occur in status")
})
