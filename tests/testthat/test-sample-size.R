test_that("balanced two-arm sample size matches numerical references", {
  # Reference totals computed independently from normal quantiles and
  # two-sample standard errors (SciPy 1.17.0): 63, 99, and 100 per arm.
  expect_equal(pharma_sample_reestimate(50, 0.5, 1), 126)
  expect_equal(pharma_sample_reestimate(50, 0.4, 1), 198)
  expect_equal(
    pharma_sample_reestimate(51, -1, 4, target_power = 0.9, alpha = 0.025),
    200
  )
  expect_equal(pharma_sample_reestimate(50, -0.5, 1), 126)

  # Verify the resulting two-sided normal-test power independently.
  n_arm <- pharma_sample_reestimate(50, 0.5, 1) / 2
  critical <- stats::qnorm(0.975)
  noncentrality <- 0.5 / sqrt(2 / n_arm)
  achieved_power <- stats::pnorm(-critical - noncentrality) +
    stats::pnorm(critical - noncentrality, lower.tail = FALSE)
  expect_true(achieved_power >= 0.8)
  expect_equal(achieved_power, 0.8013023941, tolerance = 1e-8)
})

test_that("sample size keeps a balanced floor and at least two per arm", {
  expect_equal(pharma_sample_reestimate(201, 1, 4, 0.9, 0.025), 202)
  expect_equal(pharma_sample_reestimate(70, 1, 1), 70)
  expect_equal(pharma_sample_reestimate(2, 10, 1), 4)
  expect_type(pharma_sample_reestimate(50, 0.5, 1), "double")
})

test_that("sample-size inputs have explicit domain checks", {
  for (bad in list(NA_real_, Inf, -1, 0, 1.5, c(1, 2),
                   "50", TRUE, .Machine$integer.max)) {
    expect_error(pharma_sample_reestimate(bad, 0.5, 1), "current_n")
  }
  for (bad in list(NA_real_, Inf, 0, c(0.5, 1), "0.5")) {
    expect_error(pharma_sample_reestimate(50, bad, 1), "effect")
  }
  for (bad in list(NA_real_, Inf, -1, 0, c(1, 2), "1")) {
    expect_error(pharma_sample_reestimate(50, 0.5, bad), "variance")
  }
  for (bad in list(NA_real_, Inf, 0.5, 1, c(0.8, 0.9), "0.8")) {
    expect_error(pharma_sample_reestimate(50, 0.5, 1,
                                         target_power = bad), "target_power")
  }
  for (bad in list(NA_real_, Inf, 0, 1, c(0.025, 0.05), "0.05")) {
    expect_error(pharma_sample_reestimate(50, 0.5, 1, alpha = bad), "alpha")
  }
  expect_error(pharma_sample_reestimate(50, 1e-300, 1),
               "supported range")
})
