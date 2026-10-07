cmh_reference_array <- function() {
  x <- array(
    0,
    dim = c(2, 2, 3),
    dimnames = list(
      treatment = c("Treatment", "Control"),
      outcome = c("Event", "No event"),
      stratum = c("S1", "S2", "S3")
    )
  )
  x[, , 1] <- matrix(c(12, 8, 5, 15), 2, byrow = TRUE)
  x[, , 2] <- matrix(c(20, 10, 10, 20), 2, byrow = TRUE)
  x[, , 3] <- matrix(c(8, 12, 4, 16), 2, byrow = TRUE)
  x
}

cmh_reference_components <- function(x) {
  expected <- variance <- difference <- numeric(dim(x)[3L])
  numerator <- denominator <- numeric(dim(x)[3L])

  for (k in seq_len(dim(x)[3L])) {
    tab <- x[, , k]
    a <- tab[1, 1]
    b <- tab[1, 2]
    c <- tab[2, 1]
    d <- tab[2, 2]
    n <- sum(tab)
    r1 <- sum(tab[1, ])
    r2 <- sum(tab[2, ])
    c1 <- sum(tab[, 1])
    c2 <- sum(tab[, 2])

    expected[k] <- r1 * c1 / n
    variance[k] <- r1 * r2 * c1 * c2 / (n^2 * (n - 1))
    difference[k] <- a - expected[k]
    numerator[k] <- a * d / n
    denominator[k] <- b * c / n
  }

  list(
    expected = expected,
    variance = variance,
    difference = difference,
    common_or = sum(numerator) / sum(denominator)
  )
}

test_that("CMH reproduces independent conditional moments and statistic", {
  x <- cmh_reference_array()
  ref <- cmh_reference_components(x)

  expect_equal(ref$expected, c(17 / 2, 15, 6), tolerance = 1e-12)
  expect_equal(
    ref$variance,
    c(391 / 156, 225 / 59, 28 / 13),
    tolerance = 1e-12
  )
  expect_equal(ref$difference, c(7 / 2, 5, 2), tolerance = 1e-12)

  total_difference <- sum(ref$difference)
  total_variance <- sum(ref$variance)
  expected_statistic <- total_difference^2 / total_variance

  expect_equal(total_difference, 21 / 2, tolerance = 0)
  expect_equal(total_variance, 77993 / 9204, tolerance = 1e-12)
  expect_equal(expected_statistic, 1014741 / 77993, tolerance = 1e-12)

  actual <- pharma_cmh_test(x, correct = FALSE)
  expect_s3_class(actual, "htest")
  expect_equal(unname(actual$statistic), expected_statistic, tolerance = 1e-12)
  expect_equal(unname(actual$parameter), 1, tolerance = 0)
  expect_equal(
    actual$p.value,
    stats::pchisq(expected_statistic, df = 1, lower.tail = FALSE),
    tolerance = 1e-12
  )
})

test_that("CMH common odds ratio matches the Mantel-Haenszel cross-products", {
  x <- cmh_reference_array()
  ref <- cmh_reference_components(x)

  expect_equal(ref$common_or, 431 / 116, tolerance = 1e-12)

  actual <- pharma_cmh_test(x, correct = FALSE, conf.level = 0.90)
  expect_equal(unname(actual$estimate), 431 / 116, tolerance = 1e-12)
  expect_equal(attr(actual$conf.int, "conf.level"), 0.90, tolerance = 0)
  expect_true(actual$conf.int[[1L]] < unname(actual$estimate))
  expect_true(actual$conf.int[[2L]] > unname(actual$estimate))
})

test_that("continuity correction follows the independent CMH formula", {
  x <- cmh_reference_array()
  ref <- cmh_reference_components(x)
  corrected <- (
    abs(sum(ref$difference)) - 0.5
  )^2 / sum(ref$variance)

  expect_equal(corrected, 920400 / 77993, tolerance = 1e-12)

  actual <- pharma_cmh_test(x, correct = TRUE)
  expect_equal(unname(actual$statistic), corrected, tolerance = 1e-12)
  expect_equal(
    actual$p.value,
    stats::pchisq(corrected, df = 1, lower.tail = FALSE),
    tolerance = 1e-12
  )
})

test_that("CMH is invariant to stratum order and reciprocal under row swap", {
  x <- cmh_reference_array()
  base <- pharma_cmh_test(x, correct = FALSE)

  reordered <- pharma_cmh_test(x[, , 3:1, drop = FALSE], correct = FALSE)
  expect_equal(reordered$statistic, base$statistic, tolerance = 1e-12)
  expect_equal(reordered$p.value, base$p.value, tolerance = 1e-12)
  expect_equal(reordered$estimate, base$estimate, tolerance = 1e-12)

  swapped <- pharma_cmh_test(x[2:1, , , drop = FALSE], correct = FALSE)
  expect_equal(swapped$statistic, base$statistic, tolerance = 1e-12)
  expect_equal(swapped$p.value, base$p.value, tolerance = 1e-12)
  expect_equal(
    unname(swapped$estimate),
    1 / unname(base$estimate),
    tolerance = 1e-12
  )
  expect_equal(
    as.numeric(swapped$conf.int),
    rev(1 / as.numeric(base$conf.int)),
    tolerance = 1e-10
  )
})

test_that("CMH rejects malformed and uninformative tables", {
  x <- cmh_reference_array()

  expect_error(pharma_cmh_test(matrix(1:4, 2, 2)), "2-by-2-by-K")
  expect_error(pharma_cmh_test(array(1, dim = c(2, 3, 2))), "2-by-2-by-K")

  bad <- x
  bad[1, 1, 1] <- -1
  expect_error(pharma_cmh_test(bad), "nonnegative whole-number")

  bad <- x
  bad[1, 1, 1] <- 1.5
  expect_error(pharma_cmh_test(bad), "whole-number")

  bad <- x
  bad[1, 1, 1] <- NA_real_
  expect_error(pharma_cmh_test(bad), "finite nonnegative")

  bad <- x
  bad[, , 1] <- 0
  expect_error(pharma_cmh_test(bad), "Each stratum")

  bad <- x
  bad[1, , 1] <- 0
  expect_error(pharma_cmh_test(bad), "row margins")

  expect_error(pharma_cmh_test(x, correct = NA), "correct")
  expect_error(pharma_cmh_test(x, conf.level = 1), "conf.level")
})
