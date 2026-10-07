fisher_reference_table <- function() {
  matrix(
    c(1, 9, 11, 3),
    nrow = 2,
    byrow = TRUE,
    dimnames = list(
      treatment = c("Treatment", "Control"),
      outcome = c("Event", "No event")
    )
  )
}

fisher_reference_support <- function(x) {
  a <- x[1, 1]
  row1 <- sum(x[1, ])
  col1 <- sum(x[, 1])
  col2 <- sum(x[, 2])
  total <- sum(x)

  support <- seq.int(
    max(0, row1 - col2),
    min(row1, col1)
  )
  probabilities <- vapply(support, function(value) {
    choose(col1, value) *
      choose(col2, row1 - value) /
      choose(total, row1)
  }, numeric(1))

  list(
    observed = a,
    support = support,
    probabilities = probabilities
  )
}

test_that("Fisher exact support and two-sided tail match independent enumeration", {
  x <- fisher_reference_table()
  ref <- fisher_reference_support(x)

  expect_identical(ref$support, 0:10)
  expect_equal(sum(ref$probabilities), 1, tolerance = 1e-15)

  observed_index <- match(ref$observed, ref$support)
  observed_probability <- ref$probabilities[observed_index]
  included <- ref$support[
    ref$probabilities <= observed_probability
  ]

  expect_equal(observed_probability, 10 / 7429, tolerance = 1e-15)
  expect_identical(included, c(0L, 1L, 9L, 10L))

  expected_two_sided <- sum(
    ref$probabilities[ref$probabilities <= observed_probability]
  )
  expect_equal(expected_two_sided, 41 / 14858, tolerance = 1e-15)

  actual <- pharma_fisher_test(x, alternative = "two.sided")
  expect_s3_class(actual, "htest")
  expect_equal(actual$p.value, expected_two_sided, tolerance = 1e-14)
})

test_that("Fisher one-sided tails match independent hypergeometric sums", {
  x <- fisher_reference_table()
  ref <- fisher_reference_support(x)

  expected_less <- sum(
    ref$probabilities[ref$support <= ref$observed]
  )
  expected_greater <- sum(
    ref$probabilities[ref$support >= ref$observed]
  )

  expect_equal(expected_less, 41 / 29716, tolerance = 1e-15)
  expect_equal(expected_greater, 29715 / 29716, tolerance = 1e-15)

  less <- pharma_fisher_test(x, alternative = "less")
  greater <- pharma_fisher_test(x, alternative = "greater")

  expect_equal(less$p.value, expected_less, tolerance = 1e-14)
  expect_equal(greater$p.value, expected_greater, tolerance = 1e-14)
})

test_that("Fisher odds-ratio orientation is reciprocal under row and column swaps", {
  x <- fisher_reference_table()
  base <- pharma_fisher_test(x, conf.level = 0.90)

  row_swapped <- pharma_fisher_test(x[2:1, , drop = FALSE], conf.level = 0.90)
  col_swapped <- pharma_fisher_test(x[, 2:1, drop = FALSE], conf.level = 0.90)

  expect_equal(row_swapped$p.value, base$p.value, tolerance = 1e-14)
  expect_equal(col_swapped$p.value, base$p.value, tolerance = 1e-14)

  expect_equal(
    unname(row_swapped$estimate),
    1 / unname(base$estimate),
    tolerance = 1e-10
  )
  expect_equal(
    unname(col_swapped$estimate),
    1 / unname(base$estimate),
    tolerance = 1e-10
  )
  expect_equal(
    as.numeric(row_swapped$conf.int),
    rev(1 / as.numeric(base$conf.int)),
    tolerance = 1e-9
  )
  expect_equal(
    as.numeric(col_swapped$conf.int),
    rev(1 / as.numeric(base$conf.int)),
    tolerance = 1e-9
  )
  expect_equal(attr(base$conf.int, "conf.level"), 0.90, tolerance = 0)
})

test_that("Fisher handles an informative zero-cell boundary exactly", {
  x <- matrix(c(0, 5, 4, 1), 2, byrow = TRUE)
  ref <- fisher_reference_support(x)
  observed_probability <- ref$probabilities[
    match(ref$observed, ref$support)
  ]
  expected <- sum(
    ref$probabilities[ref$probabilities <= observed_probability]
  )

  expect_equal(expected, 1 / 21, tolerance = 1e-15)

  actual <- pharma_fisher_test(x)
  expect_equal(actual$p.value, 1 / 21, tolerance = 1e-14)
  expect_equal(unname(actual$estimate), 0, tolerance = 0)
  expect_equal(as.numeric(actual$conf.int)[1L], 0, tolerance = 0)
})

test_that("Fisher rejects malformed or uninformative tables", {
  expect_error(pharma_fisher_test(1:4), "2-by-2")
  expect_error(
    pharma_fisher_test(matrix(1:6, nrow = 2)),
    "2-by-2"
  )

  bad <- fisher_reference_table()
  bad[1, 1] <- -1
  expect_error(pharma_fisher_test(bad), "nonnegative whole-number")

  bad <- fisher_reference_table()
  bad[1, 2] <- 1.5
  expect_error(pharma_fisher_test(bad), "whole-number")

  bad <- fisher_reference_table()
  bad[2, 1] <- NA_real_
  expect_error(pharma_fisher_test(bad), "finite nonnegative")

  bad <- fisher_reference_table()
  bad[1, ] <- 0
  expect_error(pharma_fisher_test(bad), "row margins")

  expect_error(
    pharma_fisher_test(fisher_reference_table(), alternative = "upper"),
    "should be one of"
  )
  expect_error(
    pharma_fisher_test(fisher_reference_table(), conf.level = 1),
    "conf.level"
  )
})
