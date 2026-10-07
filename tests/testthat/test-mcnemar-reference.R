mcnemar_reference_table <- function() {
  matrix(
    c(30, 12, 4, 24),
    nrow = 2,
    byrow = TRUE,
    dimnames = list(
      first = c("Positive", "Negative"),
      second = c("Positive", "Negative")
    )
  )
}

test_that("McNemar asymptotic statistics match independent discordant arithmetic", {
  x <- mcnemar_reference_table()

  uncorrected <- pharma_mcnemar_test(x, correct = FALSE)
  corrected <- pharma_mcnemar_test(x, correct = TRUE)

  expect_s3_class(uncorrected, "htest")
  expect_identical(
    unname(uncorrected$discordant),
    c(12, 4)
  )
  expect_equal(uncorrected$n.discordant, 16, tolerance = 0)

  expect_equal(
    unname(uncorrected$statistic),
    (12 - 4)^2 / 16,
    tolerance = 0
  )
  expect_equal(unname(uncorrected$statistic), 4, tolerance = 0)
  expect_equal(
    uncorrected$p.value,
    stats::pchisq(4, df = 1, lower.tail = FALSE),
    tolerance = 1e-12
  )

  expect_equal(
    unname(corrected$statistic),
    (abs(12 - 4) - 1)^2 / 16,
    tolerance = 0
  )
  expect_equal(unname(corrected$statistic), 49 / 16, tolerance = 0)
  expect_equal(
    corrected$p.value,
    stats::pchisq(49 / 16, df = 1, lower.tail = FALSE),
    tolerance = 1e-12
  )
})

test_that("McNemar exact p-value matches finite binomial support", {
  x <- mcnemar_reference_table()
  result <- pharma_mcnemar_test(x)

  probabilities <- vapply(0:16, function(k) {
    choose(16, k) / 2^16
  }, numeric(1))
  lower_tail <- sum(probabilities[1:5])
  expected <- 2 * lower_tail

  expect_equal(lower_tail, 2517 / 65536, tolerance = 0)
  expect_equal(expected, 2517 / 32768, tolerance = 0)
  expect_equal(result$exact.p.value, expected, tolerance = 1e-15)
})

test_that("McNemar ignores concordant cells and is invariant to condition swap", {
  x <- mcnemar_reference_table()
  base <- pharma_mcnemar_test(x, correct = FALSE)

  changed_diagonal <- x
  changed_diagonal[1, 1] <- 300
  changed_diagonal[2, 2] <- 2
  changed <- pharma_mcnemar_test(changed_diagonal, correct = FALSE)

  expect_equal(changed$statistic, base$statistic, tolerance = 0)
  expect_equal(changed$p.value, base$p.value, tolerance = 0)
  expect_equal(changed$exact.p.value, base$exact.p.value, tolerance = 0)

  swapped <- pharma_mcnemar_test(t(x), correct = FALSE)
  expect_equal(swapped$statistic, base$statistic, tolerance = 0)
  expect_equal(swapped$p.value, base$p.value, tolerance = 0)
  expect_equal(swapped$exact.p.value, base$exact.p.value, tolerance = 0)
  expect_identical(
    unname(swapped$discordant),
    rev(unname(base$discordant))
  )
})

test_that("McNemar handles no-discordance and tied-discordance boundaries", {
  no_discordance <- matrix(c(12, 0, 0, 9), 2, byrow = TRUE)
  zero <- pharma_mcnemar_test(no_discordance)

  expect_equal(unname(zero$statistic), 0, tolerance = 0)
  expect_equal(zero$p.value, 1, tolerance = 0)
  expect_equal(zero$exact.p.value, 1, tolerance = 0)
  expect_equal(zero$n.discordant, 0, tolerance = 0)

  tied <- matrix(c(7, 5, 5, 8), 2, byrow = TRUE)
  tie_result <- pharma_mcnemar_test(tied)
  expect_equal(unname(tie_result$statistic), 0, tolerance = 0)
  expect_equal(tie_result$p.value, 1, tolerance = 0)
  expect_equal(tie_result$exact.p.value, 1, tolerance = 0)
})

test_that("McNemar rejects malformed paired-count tables", {
  expect_error(pharma_mcnemar_test(1:4), "2-by-2")
  expect_error(
    pharma_mcnemar_test(matrix(1:6, nrow = 2)),
    "2-by-2"
  )

  bad <- mcnemar_reference_table()
  bad[1, 1] <- -1
  expect_error(pharma_mcnemar_test(bad), "nonnegative whole-number")

  bad <- mcnemar_reference_table()
  bad[1, 2] <- 1.5
  expect_error(pharma_mcnemar_test(bad), "whole-number")

  bad <- mcnemar_reference_table()
  bad[2, 1] <- NA_real_
  expect_error(pharma_mcnemar_test(bad), "finite nonnegative")

  expect_error(pharma_mcnemar_test(mcnemar_reference_table(), correct = NA),
               "correct")
})
