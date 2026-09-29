# Fixed references were computed from the stated sufficient statistics with
# SciPy 1.17.0 distribution tails and quantiles. See docs/core-reference-cases.md.
# These expectations do not call the functions used inside the wrappers.

test_that("Welch t test reproduces estimate, tails, df, and interval", {
  x <- c(1, 2, 3, 4)
  y <- c(2, 4, 6, 8)

  # Means 2.5 and 5; sample variances 5/3 and 20/3. The Welch standard
  # error is 5/sqrt(12), t = -sqrt(3), and df = 75/17.
  result <- pharma_t_test(x, y)
  expect_equal(unname(result$estimate), c(2.5, 5))
  expect_equal(unname(result$statistic), -sqrt(3), tolerance = 1e-12)
  expect_equal(unname(result$parameter), 75 / 17, tolerance = 1e-12)
  expect_equal(result$p.value, 0.15158050484530375, tolerance = 1e-12)
  expect_equal(as.numeric(result$conf.int),
               c(-6.364167215486198, 1.364167215486198),
               tolerance = 1e-10)

  # A lower-tail alternative changes the p-value and gives a one-sided CI.
  lower <- pharma_t_test(x, y, alternative = "less")
  expect_equal(lower$p.value, 0.07579025242265187, tolerance = 1e-12)
  expect_equal(as.numeric(lower$conf.int[1L]), -Inf)
  expect_equal(unname(lower$conf.int[2L]), 0.4963652572315209,
               tolerance = 1e-10)

  pooled <- pharma_t_test(x, y, var.equal = TRUE)
  expect_equal(unname(pooled$parameter), 6)
  expect_equal(pooled$p.value, 0.1339745962155613, tolerance = 1e-12)
})

test_that("t-test formula order and incomplete rows follow the stated contract", {
  data <- data.frame(
    response = c(1, 2, 3, 4, 2, 4, 6, 8),
    group = factor(rep(c("A", "B"), each = 4L), levels = c("A", "B"))
  )
  result <- pharma_t_test(response ~ group, data = data)
  expect_equal(unname(result$statistic), -sqrt(3), tolerance = 1e-12)
  data$response[1L] <- NA_real_
  expect_error(pharma_t_test(response ~ group, data = data), "NA values")
})

test_that("Welch TOST reproduces both one-sided tails and its 90 percent CI", {
  x <- c(2, 3, 4, 5)
  y <- c(1, 2, 3, 4)

  # Difference 1; each sample variance 5/3; SE sqrt(5/6); Welch df 6.
  # With bounds (-1, 3), both one-sided p-values are 0.03549382716.
  result <- pharma_tost(x, y, -1, 3)
  expect_equal(result$diff, 1)
  expect_equal(result$df, 6)
  expect_equal(unname(result$statistic),
               c(2.1908902300206643, -2.1908902300206643),
               tolerance = 1e-12)
  expect_equal(result$p.value, 0.03549382716049381, tolerance = 1e-12)
  expect_equal(as.numeric(result$conf.int),
               c(-0.773872788229081, 2.773872788229081),
               tolerance = 1e-10)
  expect_true(result$p.value < 0.05)

  # Tightening only the upper bound must make the upper-tail test fail.
  narrow <- pharma_tost(x, y, -1, 2)
  expect_equal(narrow$p.value, 0.15766679810061496, tolerance = 1e-12)
  expect_true(narrow$p.value > 0.05)
  expect_error(pharma_tost(rep(2, 4), rep(1, 4), -1, 3), "variance")
})

test_that("Pearson chi-square distinguishes uncorrected and Yates tests", {
  counts <- matrix(c(10, 20, 20, 10), nrow = 2L, byrow = TRUE)
  # Independence gives 15 expected observations in every cell. With one
  # degree of freedom, Pearson X^2 = 20/3 and Yates X^2 = 5.4.
  pearson <- pharma_chisq_test(counts, correct = FALSE)
  expect_equal(as.numeric(pearson$expected), rep(15, 4))
  expect_equal(unname(pearson$statistic), 20 / 3, tolerance = 1e-12)
  expect_equal(unname(pearson$parameter), 1)
  expect_equal(pearson$p.value, 0.009823274507519235, tolerance = 1e-12)

  corrected <- pharma_chisq_test(counts)
  expect_equal(unname(corrected$statistic), 5.4, tolerance = 1e-12)
  expect_equal(corrected$p.value, 0.02013675155034633,
               tolerance = 1e-12)
  expect_true(corrected$p.value > pearson$p.value)
  counts[1L, 1L] <- -1
  expect_error(pharma_chisq_test(counts), "nonnegative")
})

test_that("one-way ANOVA reproduces hand-calculated sums of squares and F", {
  data <- data.frame(
    response = as.numeric(1:9),
    group = factor(rep(c("A", "B", "C"), each = 3L))
  )
  # Group means 2, 5, 8; grand mean 5. Between SS = 54, within SS = 6;
  # df = (2, 6), MS = (27, 1), F = 27, upper-tail p = 0.001.
  fit <- pharma_anova(response ~ group, data = data)
  table <- summary(fit)[[1L]]
  expect_equal(unname(stats::coef(fit)), c(2, 3, 6))
  expect_equal(as.numeric(table[["Df"]]), c(2, 6))
  expect_equal(as.numeric(table[["Sum Sq"]]), c(54, 6), tolerance = 1e-12)
  expect_equal(as.numeric(table[["Mean Sq"]]), c(27, 1), tolerance = 1e-12)
  expect_equal(unname(table[["F value"]][1L]), 27, tolerance = 1e-12)
  expect_equal(unname(table[["Pr(>F)"]][1L]), 0.001, tolerance = 1e-12)

  data$group <- 1:9
  expect_error(pharma_anova(response ~ group, data = data), "categorical")
})
