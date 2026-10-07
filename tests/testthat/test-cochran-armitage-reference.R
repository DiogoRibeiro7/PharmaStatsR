ca_reference_table <- function() {
  cbind(
    events = c(2, 5, 9, 14),
    nonevents = c(18, 15, 11, 6)
  )
}

ca_reference_components <- function(x, scores = 0:(nrow(x) - 1L)) {
  totals <- rowSums(x)
  events <- x[, 1L]
  n <- sum(totals)
  p <- sum(events) / n
  q <- 1 - p
  numerator <- sum(scores * (events - totals * p))
  variance <- p * q * (
    sum(totals * scores^2) -
      sum(totals * scores)^2 / n
  )
  list(
    p = p,
    numerator = numerator,
    variance = variance,
    z = numerator / sqrt(variance)
  )
}

test_that("Cochran-Armitage matches independent score arithmetic", {
  x <- ca_reference_table()
  ref <- ca_reference_components(x)

  expect_equal(ref$p, 3 / 8, tolerance = 0)
  expect_equal(ref$numerator, 20, tolerance = 0)
  expect_equal(ref$variance, 375 / 16, tolerance = 1e-12)
  expect_equal(ref$z, 16 / sqrt(15), tolerance = 1e-12)

  actual <- pharma_cochran_armitage_test(x)
  expect_s3_class(actual, "htest")
  expect_equal(unname(actual$statistic), 16 / sqrt(15), tolerance = 1e-12)
  expect_equal(actual$pooled.event.rate, 3 / 8, tolerance = 0)
  expect_equal(
    actual$p.value,
    2 * stats::pnorm(-16 / sqrt(15)),
    tolerance = 1e-15
  )
})

test_that("Cochran-Armitage one-sided tails use the signed Z statistic", {
  x <- ca_reference_table()
  z <- 16 / sqrt(15)

  greater <- pharma_cochran_armitage_test(x, alternative = "greater")
  less <- pharma_cochran_armitage_test(x, alternative = "less")

  expect_equal(greater$p.value, stats::pnorm(z, lower.tail = FALSE),
               tolerance = 1e-15)
  expect_equal(less$p.value, stats::pnorm(z), tolerance = 1e-15)
  expect_lt(greater$p.value, 0.001)
  expect_gt(less$p.value, 0.999)
})

test_that("trend statistic is invariant to score translation and positive scale", {
  x <- ca_reference_table()
  base <- pharma_cochran_armitage_test(x, scores = c(0, 1, 2, 3))

  translated <- pharma_cochran_armitage_test(
    x, scores = c(10, 11, 12, 13)
  )
  scaled <- pharma_cochran_armitage_test(
    x, scores = c(0, 5, 10, 15)
  )

  expect_equal(translated$statistic, base$statistic, tolerance = 1e-12)
  expect_equal(translated$p.value, base$p.value, tolerance = 1e-15)
  expect_equal(scaled$statistic, base$statistic, tolerance = 1e-12)
  expect_equal(scaled$p.value, base$p.value, tolerance = 1e-15)
})

test_that("reversing ordered groups reverses the trend direction", {
  x <- ca_reference_table()
  base <- pharma_cochran_armitage_test(x, alternative = "greater")

  reversed <- pharma_cochran_armitage_test(
    x[4:1, , drop = FALSE],
    scores = 0:3,
    alternative = "less"
  )

  expect_equal(
    unname(reversed$statistic),
    -unname(base$statistic),
    tolerance = 1e-12
  )
  expect_equal(reversed$p.value, base$p.value, tolerance = 1e-15)
})

test_that("swapping event and non-event columns reverses Z", {
  x <- ca_reference_table()
  base <- pharma_cochran_armitage_test(x, alternative = "greater")
  swapped <- pharma_cochran_armitage_test(
    x[, 2:1, drop = FALSE],
    alternative = "less"
  )

  expect_equal(
    unname(swapped$statistic),
    -unname(base$statistic),
    tolerance = 1e-12
  )
  expect_equal(swapped$p.value, base$p.value, tolerance = 1e-15)
})

test_that("Cochran-Armitage rejects malformed or degenerate inputs", {
  x <- ca_reference_table()

  expect_error(pharma_cochran_armitage_test(1:8), "K-by-2")
  expect_error(
    pharma_cochran_armitage_test(matrix(1:6, nrow = 2)),
    "K-by-2"
  )

  bad <- x
  bad[1, 1] <- -1
  expect_error(pharma_cochran_armitage_test(bad), "nonnegative whole-number")

  bad <- x
  bad[1, 1] <- 1.5
  expect_error(pharma_cochran_armitage_test(bad), "whole-number")

  bad <- x
  bad[1, ] <- 0
  expect_error(pharma_cochran_armitage_test(bad), "positive total")

  expect_error(
    pharma_cochran_armitage_test(x, scores = c(0, 1, 1, 2)),
    "strictly increasing"
  )
  expect_error(
    pharma_cochran_armitage_test(x, scores = 1:3),
    "one score per group"
  )

  all_no_events <- cbind(events = rep(0, 4), nonevents = rep(20, 4))
  expect_error(
    pharma_cochran_armitage_test(all_no_events),
    "strictly between 0 and 1"
  )

  expect_error(
    pharma_cochran_armitage_test(x, alternative = "up"),
    "should be one of"
  )
})
