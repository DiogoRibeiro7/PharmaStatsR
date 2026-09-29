test_that("formula t-test rejects missing analysis values", {
  data <- data.frame(
    outcome = c(1, 2, 3, 4, 5, 6),
    group = factor(rep(c("A", "B"), each = 3))
  )
  for (column in c("outcome", "group")) {
    incomplete <- data
    incomplete[[column]][1L] <- NA
    expect_error(
      pharma_t_test(outcome ~ group, data = incomplete),
      "contain NA values"
    )
  }

  expect_equal(
    pharma_t_test(outcome ~ group, data = data)$statistic,
    stats::t.test(outcome ~ group, data = data)$statistic
  )
})

test_that("one-way ANOVA rejects missing analysis values", {
  data <- data.frame(
    outcome = c(1, 2, 3, 4, 5, 6),
    group = factor(rep(c("A", "B"), each = 3))
  )
  for (column in c("outcome", "group")) {
    incomplete <- data
    incomplete[[column]][1L] <- NA
    expect_error(
      pharma_anova(outcome ~ group, data = incomplete),
      "contain NA values"
    )
  }

  expect_equal(
    stats::coef(pharma_anova(outcome ~ group, data = data)),
    stats::coef(stats::aov(outcome ~ group, data = data))
  )
})
