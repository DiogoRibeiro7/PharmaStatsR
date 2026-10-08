breslow_day_reference_array <- function() {
  x <- array(0, dim = c(2, 2, 2))
  x[, , 1] <- matrix(c(8, 2, 2, 8), 2, byrow = TRUE)
  x[, , 2] <- matrix(c(2, 8, 8, 2), 2, byrow = TRUE)
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
  expect_equal(unname(actual$parameter), 1, tolerance = 0)
  expect_equal(
    actual$p.value,
    stats::pchisq(expected, df = 1, lower.tail = FALSE),
    tolerance = 1e-12
  )
})

test_that("Breslow-Day is invariant to stratum order", {
  x <- breslow_day_reference_array()
  base <- pharma_breslow_day_test(x)
  reordered <- pharma_breslow_day_test(x[, , 2:1, drop = FALSE])

  expect_equal(reordered$statistic, base$statistic, tolerance = 1e-12)
  expect_equal(reordered$p.value, base$p.value, tolerance = 1e-12)
  expect_equal(
    reordered$common.odds.ratio,
    base$common.odds.ratio,
    tolerance = 1e-12
  )
  expect_equal(
    reordered$fitted.upper.left,
    rev(base$fitted.upper.left),
    tolerance = 1e-10
  )
})

test_that("Breslow-Day returns zero for homogeneous identical strata", {
  x <- array(0, dim = c(2, 2, 3))
  tab <- matrix(c(8, 2, 2, 8), 2, byrow = TRUE)
  x[, , 1] <- tab
  x[, , 2] <- tab
  x[, , 3] <- tab

  result <- pharma_breslow_day_test(x)

  expect_equal(unname(result$statistic), 0, tolerance = 1e-10)
  expect_equal(unname(result$parameter), 2, tolerance = 0)
  expect_equal(result$p.value, 1, tolerance = 1e-12)
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
})
