bowker_reference_table <- function() {
  matrix(c(
    20, 8, 2,
    2, 15, 5,
    1, 3, 14
  ), 3, byrow = TRUE)
}

test_that("Bowker matches independent pairwise symmetry arithmetic", {
  x <- bowker_reference_table()

  expected_contributions <- c(
    "1:2" = (8 - 2)^2 / (8 + 2),
    "1:3" = (2 - 1)^2 / (2 + 1),
    "2:3" = (5 - 3)^2 / (5 + 3)
  )
  expected <- 133 / 30

  expect_equal(sum(expected_contributions), expected, tolerance = 1e-15)

  actual <- pharma_bowker_test(x)
  expect_equal(actual$pair.contributions, expected_contributions, tolerance = 1e-15)
  expect_equal(unname(actual$statistic), expected, tolerance = 1e-15)
  expect_equal(unname(actual$parameter), 3, tolerance = 0)
  expect_equal(
    actual$p.value,
    stats::pchisq(expected, df = 3, lower.tail = FALSE),
    tolerance = 1e-15
  )
})

test_that("Bowker is invariant to category permutation and transposition", {
  x <- bowker_reference_table()
  base <- pharma_bowker_test(x)

  p <- c(3, 1, 2)
  permuted <- pharma_bowker_test(x[p, p, drop = FALSE])
  transposed <- pharma_bowker_test(t(x))

  expect_equal(permuted$statistic, base$statistic, tolerance = 1e-15)
  expect_equal(permuted$p.value, base$p.value, tolerance = 1e-15)
  expect_equal(transposed$statistic, base$statistic, tolerance = 1e-15)
  expect_equal(transposed$p.value, base$p.value, tolerance = 1e-15)
})

test_that("two-category Bowker equals uncorrected McNemar", {
  x <- matrix(c(1, 3, 1, 1), 2, byrow = TRUE)

  bowker <- pharma_bowker_test(x)
  mcnemar <- pharma_mcnemar_test(x, correct = FALSE)

  expect_equal(
    unname(bowker$statistic),
    unname(mcnemar$statistic),
    tolerance = 0
  )
  expect_equal(bowker$p.value, mcnemar$p.value, tolerance = 0)
  expect_equal(unname(bowker$parameter), 1, tolerance = 0)
})

test_that("Bowker returns zero for a symmetric informative table", {
  x <- matrix(c(
    10, 2, 1,
    2, 12, 3,
    1, 3, 8
  ), 3, byrow = TRUE)

  result <- pharma_bowker_test(x)

  expect_equal(unname(result$statistic), 0, tolerance = 0)
  expect_equal(unname(result$parameter), 3, tolerance = 0)
  expect_equal(result$p.value, 1, tolerance = 0)
  expect_equal(result$pair.contributions, c("1:2" = 0, "1:3" = 0, "2:3" = 0))
})

test_that("Bowker uses only informative off-diagonal pairs for df", {
  x <- matrix(c(
    5, 4, 0,
    2, 6, 0,
    0, 0, 7
  ), 3, byrow = TRUE)

  result <- pharma_bowker_test(x)

  expect_equal(unname(result$statistic), (4 - 2)^2 / 6, tolerance = 0)
  expect_equal(unname(result$parameter), 1, tolerance = 0)
  expect_equal(names(result$pair.contributions), "1:2")
})

test_that("Bowker rejects malformed or uninformative tables", {
  expect_error(pharma_bowker_test(matrix(1:6, 2, 3)), "square")
  expect_error(pharma_bowker_test(matrix(1:1, 1, 1)), "K >= 2")

  bad <- bowker_reference_table()
  bad[1, 1] <- -1
  expect_error(pharma_bowker_test(bad), "nonnegative whole-number")

  bad <- bowker_reference_table()
  bad[1, 2] <- 1.5
  expect_error(pharma_bowker_test(bad), "whole-number")

  expect_error(pharma_bowker_test(matrix(0, 3, 3)), "at least one paired")

  diagonal_only <- diag(c(3, 4, 5))
  expect_error(pharma_bowker_test(diagonal_only), "off-diagonal")
})
