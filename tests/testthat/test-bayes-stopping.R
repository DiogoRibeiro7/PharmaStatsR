test_that("single-arm posterior matches independent beta references", {
  # Beta(9, 3) at 0.5: P(p > 0.5) = 1981 / 2048.
  out <- pharma_bayes_stopping(1, 1, successes = 8, trials = 10)
  expect_named(out, c("prob", "stop"))
  expect_equal(out$prob, 1981 / 2048, tolerance = 1e-12)
  expect_identical(out$stop, TRUE)

  equal_cutoff <- pharma_bayes_stopping(
    1, 1, successes = 8, trials = 10, threshold = out$prob
  )
  expect_identical(equal_cutoff$stop, FALSE)

  # Independent SciPy Beta(7, 8) reference for a benchmark of 0.4.
  shifted <- pharma_bayes_stopping(
    2, 3, successes = 5, trials = 10,
    threshold = 0.7, null_rate = 0.4
  )
  expect_equal(shifted$prob, 0.6924521978265601, tolerance = 1e-12)
  expect_identical(shifted$stop, FALSE)
})

test_that("rare upper-tail probabilities do not cancel to zero", {
  # The Beta(1, 61) upper tail above 0.5 equals 2^-61 exactly.
  out <- pharma_bayes_stopping(1, 1, successes = 0, trials = 60)
  expect_gt(out$prob, 0)
  expect_equal(out$prob, 2^-61, tolerance = 1e-12)
  expect_identical(out$stop, FALSE)
})

test_that("prior shapes, counts, and cutoffs are validated", {
  invalid_shapes <- list(NA_real_, Inf, -1, 0, c(1, 2), "1", TRUE)
  for (bad in invalid_shapes) {
    expect_error(pharma_bayes_stopping(bad, 1, 1, 2), "prior_alpha")
    expect_error(pharma_bayes_stopping(1, bad, 1, 2), "prior_beta")
  }
  for (bad in list(NA_real_, Inf, -1, 1.5, c(1, 2), "1", TRUE)) {
    expect_error(pharma_bayes_stopping(1, 1, bad, 2), "successes")
  }
  for (bad in list(NA_real_, Inf, -1, 0, 1.5, c(1, 2),
                   "2", TRUE, .Machine$integer.max + 1)) {
    expect_error(pharma_bayes_stopping(1, 1, 0, bad), "trials")
  }
  expect_error(pharma_bayes_stopping(1, 1, 3, 2), "cannot exceed")
  for (bad in list(NA_real_, Inf, -1, 0, 1, c(0.8, 0.9), "0.95")) {
    expect_error(pharma_bayes_stopping(1, 1, 1, 2, threshold = bad),
                 "threshold")
    expect_error(pharma_bayes_stopping(1, 1, 1, 2, null_rate = bad),
                 "null_rate")
  }
})
