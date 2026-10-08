woolf_reference_array <- function() {
  x <- array(0, dim = c(2, 2, 3))
  x[, , 1] <- matrix(c(8, 2, 2, 8), 2, byrow = TRUE)
  x[, , 2] <- matrix(c(6, 4, 3, 7), 2, byrow = TRUE)
  x[, , 3] <- matrix(c(9, 1, 4, 6), 2, byrow = TRUE)
  x
}

test_that("Woolf matches independent inverse-variance arithmetic", {
  x <- woolf_reference_array()

  log_or <- c(
    log(8 * 8 / (2 * 2)),
    log(6 * 7 / (4 * 3)),
    log(9 * 6 / (1 * 4))
  )
  variance <- c(
    1 / 8 + 1 / 2 + 1 / 2 + 1 / 8,
    1 / 6 + 1 / 4 + 1 / 3 + 1 / 7,
    1 / 9 + 1 + 1 / 4 + 1 / 6
  )
  weight <- 1 / variance
  pooled <- sum(weight * log_or) / sum(weight)
  expected <- sum(weight * (log_or - pooled)^2)

  expect_equal(log_or, c(
    2.772588722239781,
    1.252762968495368,
    2.602689685444384
  ), tolerance = 1e-15)
  expect_equal(variance, c(1.25, 25 / 28, 55 / 36), tolerance = 1e-15)
  expect_equal(weight, c(0.8, 1.12, 36 / 55), tolerance = 1e-15)
  expect_equal(pooled, 2.068226916058353, tolerance = 1e-15)
  expect_equal(expected, 1.328650871807416, tolerance = 1e-15)

  actual <- pharma_woolf_test(x)

  expect_equal(actual$stratum.log.odds.ratio, log_or, tolerance = 1e-15)
  expect_equal(actual$stratum.variance, variance, tolerance = 1e-15)
  expect_equal(actual$stratum.weight, weight, tolerance = 1e-15)
  expect_equal(actual$pooled.log.odds.ratio, pooled, tolerance = 1e-15)
  expect_equal(actual$pooled.odds.ratio, exp(pooled), tolerance = 1e-15)
  expect_equal(unname(actual$statistic), expected, tolerance = 1e-15)
  expect_equal(unname(actual$parameter), 2, tolerance = 0)
  expect_equal(
    actual$p.value,
    stats::pchisq(expected, df = 2, lower.tail = FALSE),
    tolerance = 1e-15
  )
})

test_that("Woolf is invariant to stratum order", {
  x <- woolf_reference_array()
  p <- c(3, 1, 2)

  base <- pharma_woolf_test(x)
  reordered <- pharma_woolf_test(x[, , p, drop = FALSE])

  expect_equal(reordered$statistic, base$statistic, tolerance = 1e-15)
  expect_equal(reordered$p.value, base$p.value, tolerance = 1e-15)
  expect_equal(
    reordered$pooled.log.odds.ratio,
    base$pooled.log.odds.ratio,
    tolerance = 1e-15
  )
  expect_equal(
    reordered$stratum.log.odds.ratio,
    base$stratum.log.odds.ratio[p],
    tolerance = 1e-15
  )
})

test_that("Woolf returns zero for identical strata", {
  x <- array(0, dim = c(2, 2, 3))
  tab <- matrix(c(8, 2, 2, 8), 2, byrow = TRUE)
  x[, , 1] <- tab
  x[, , 2] <- tab
  x[, , 3] <- tab

  result <- pharma_woolf_test(x)

  expect_equal(unname(result$statistic), 0, tolerance = 1e-15)
  expect_equal(unname(result$parameter), 2, tolerance = 0)
  expect_equal(result$p.value, 1, tolerance = 0)
})

test_that("Woolf rejects malformed and zero-cell inputs", {
  x <- woolf_reference_array()

  expect_error(pharma_woolf_test(matrix(1:4, 2, 2)), "2-by-2-by-K")
  expect_error(
    pharma_woolf_test(array(1, dim = c(2, 2, 1))),
    "K >= 2"
  )
  expect_error(
    pharma_woolf_test(array(1, dim = c(2, 3, 2))),
    "2-by-2-by-K"
  )

  bad <- x
  bad[1, 1, 1] <- 0
  expect_error(pharma_woolf_test(bad), "strictly positive")

  bad <- x
  bad[1, 1, 1] <- -1
  expect_error(pharma_woolf_test(bad), "strictly positive")

  bad <- x
  bad[1, 1, 1] <- 1.5
  expect_error(pharma_woolf_test(bad), "whole-number")
})
