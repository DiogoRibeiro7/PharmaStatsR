breslow_day_reference_array <- function() {
  x <- array(0, dim = c(2, 2, 2))
  x[, , 1] <- matrix(c(8, 2, 2, 8), 2, byrow = TRUE)
  x[, , 2] <- matrix(c(2, 8, 8, 2), 2, byrow = TRUE)
  x
}

breslow_day_tarone_reference_array <- function() {
  x <- array(0, dim = c(2, 2, 3))
  x[, , 1] <- matrix(c(8, 2, 2, 8), 2, byrow = TRUE)
  x[, , 2] <- matrix(c(2, 8, 5, 5), 2, byrow = TRUE)
  x[, , 3] <- matrix(c(9, 1, 4, 6), 2, byrow = TRUE)
  x
}

test_that("Breslow-Day matches the independent two-stratum reference", {
  x <- breslow_day_reference_array()

  common_or <- (
    8 * 8 / 20 + 2 * 2 / 20
  ) / (
    2 * 2 / 20 + 8 * 8 / 20
  )
  fitted <- c(5, 5)
  variance <- c(5 / 4, 5 / 4)
  contributions <- c(
    (8 - 5)^2 / (5 / 4),
    (2 - 5)^2 / (5 / 4)
  )
  expected <- 72 / 5

  expect_equal(common_or, 1, tolerance = 0)
  expect_equal(sum(contributions), expected, tolerance = 0)

  actual <- pharma_breslow_day_test(x)

  expect_equal(actual$common.odds.ratio, 1, tolerance = 1e-12)
  expect_equal(actual$fitted.upper.left, fitted, tolerance = 1e-10)
  expect_equal(actual$stratum.variance, variance, tolerance = 1e-10)
  expect_equal(actual$stratum.contributions, contributions, tolerance = 1e-10)
  expect_equal(unname(actual$statistic), expected, tolerance = 1e-10)
  expect_equal(actual$unadjusted.statistic, expected, tolerance = 1e-10)
  expect_equal(actual$tarone.correction, 0, tolerance = 1e-10)
  expect_false(actual$tarone)
  expect_equal(unname(actual$parameter), 1, tolerance = 0)
  expect_equal(
    actual$p.value,
    stats::pchisq(expected, df = 1, lower.tail = FALSE),
    tolerance = 1e-12
  )
})

test_that("Tarone adjustment matches an independent three-stratum reference", {
  x <- breslow_day_tarone_reference_array()

  common_or <- 8 / 3
  expected_fitted <- c(
    6.20204102886729,
    4.58788619911651,
    7.58788619911651
  )
  expected_variance <- c(
    1.17775487412734,
    1.05363070815184,
    1.05363070815184
  )
  expected_differences <- c(
    1.79795897113271,
    -2.58788619911651,
    1.41211380088349
  )
  expected_unadjusted <- 10.9935914670981
  expected_correction <- 0.117842986781001
  expected_adjusted <- 10.8757484803171

  actual <- pharma_breslow_day_test(x, tarone = TRUE)

  expect_equal(actual$common.odds.ratio, common_or, tolerance = 1e-12)
  expect_equal(actual$fitted.upper.left, expected_fitted, tolerance = 1e-8)
  expect_equal(actual$stratum.variance, expected_variance, tolerance = 1e-8)
  expect_equal(actual$stratum.difference, expected_differences, tolerance = 1e-8)
  expect_equal(actual$unadjusted.statistic, expected_unadjusted, tolerance = 1e-8)
  expect_equal(actual$tarone.correction, expected_correction, tolerance = 1e-8)
  expect_equal(unname(actual$statistic), expected_adjusted, tolerance = 1e-8)
  expect_true(actual$tarone)
  expect_equal(unname(actual$parameter), 2, tolerance = 0)
  expect_equal(
    actual$p.value,
    stats::pchisq(expected_adjusted, df = 2, lower.tail = FALSE),
    tolerance = 1e-10
  )
})

test_that("Tarone false preserves the unadjusted Breslow-Day statistic", {
  x <- breslow_day_tarone_reference_array()

  default <- pharma_breslow_day_test(x)
  explicit <- pharma_breslow_day_test(x, tarone = FALSE)
  adjusted <- pharma_breslow_day_test(x, tarone = TRUE)

  expect_equal(explicit$statistic, default$statistic, tolerance = 0)
  expect_equal(explicit$p.value, default$p.value, tolerance = 0)
  expect_equal(
    unname(adjusted$statistic),
    adjusted$unadjusted.statistic - adjusted$tarone.correction,
    tolerance = 1e-12
  )
  expect_lte(
    unname(adjusted$statistic),
    adjusted$unadjusted.statistic
  )
})

test_that("Breslow-Day and Tarone adjustment are invariant to stratum order", {
  x <- breslow_day_tarone_reference_array()
  p <- c(3, 1, 2)

  for (tarone in c(FALSE, TRUE)) {
    base <- pharma_breslow_day_test(x, tarone = tarone)
    reordered <- pharma_breslow_day_test(
      x[, , p, drop = FALSE],
      tarone = tarone
    )

    expect_equal(reordered$statistic, base$statistic, tolerance = 1e-10)
    expect_equal(reordered$p.value, base$p.value, tolerance = 1e-10)
    expect_equal(
      reordered$common.odds.ratio,
      base$common.odds.ratio,
      tolerance = 1e-12
    )
    expect_equal(
      reordered$fitted.upper.left,
      base$fitted.upper.left[p],
      tolerance = 1e-8
    )
  }
})

test_that("Breslow-Day returns zero for homogeneous identical strata", {
  x <- array(0, dim = c(2, 2, 3))
  tab <- matrix(c(8, 2, 2, 8), 2, byrow = TRUE)
  x[, , 1] <- tab
  x[, , 2] <- tab
  x[, , 3] <- tab

  unadjusted <- pharma_breslow_day_test(x)
  adjusted <- pharma_breslow_day_test(x, tarone = TRUE)

  expect_equal(unname(unadjusted$statistic), 0, tolerance = 1e-10)
  expect_equal(unname(adjusted$statistic), 0, tolerance = 1e-10)
  expect_equal(unname(unadjusted$parameter), 2, tolerance = 0)
  expect_equal(unadjusted$p.value, 1, tolerance = 1e-12)
  expect_equal(adjusted$p.value, 1, tolerance = 1e-12)
})

test_that("Breslow-Day rejects malformed or degenerate inputs", {
  x <- breslow_day_reference_array()

  expect_error(
    pharma_breslow_day_test(matrix(1:4, 2, 2)),
    "2-by-2-by-K"
  )
  expect_error(
    pharma_breslow_day_test(array(1, dim = c(2, 2, 1))),
    "K >= 2"
  )
  expect_error(
    pharma_breslow_day_test(array(1, dim = c(2, 3, 2))),
    "2-by-2-by-K"
  )

  bad <- x
  bad[1, 1, 1] <- -1
  expect_error(
    pharma_breslow_day_test(bad),
    "nonnegative whole-number"
  )

  bad <- x
  bad[1, 1, 1] <- 1.5
  expect_error(
    pharma_breslow_day_test(bad),
    "whole-number"
  )

  bad <- x
  bad[, , 1] <- 0
  expect_error(pharma_breslow_day_test(bad), "Each stratum")

  bad <- array(0, dim = c(2, 2, 2))
  bad[, , 1] <- matrix(c(5, 0, 0, 5), 2, byrow = TRUE)
  bad[, , 2] <- matrix(c(6, 0, 0, 6), 2, byrow = TRUE)
  expect_error(
    pharma_breslow_day_test(bad),
    "common odds ratio"
  )

  expect_error(pharma_breslow_day_test(x, tarone = NA), "tarone")
  expect_error(pharma_breslow_day_test(x, tarone = 1), "tarone")
})
