test_that("TOST matches independent Welch tests and their confidence interval", {
  x <- c(3.1, 3.4, 3.8, 4.0, 4.2, 4.6)
  y <- c(2.7, 3.2, 5.0, 6.1, 7.4)
  lower_bound <- -2
  upper_bound <- 2
  alpha <- 0.05

  result <- pharma_tost(x, y, lower_bound, upper_bound, alpha)
  lower_test <- stats::t.test(x, y, mu = lower_bound, alternative = "greater")
  upper_test <- stats::t.test(x, y, mu = upper_bound, alternative = "less")
  interval_test <- stats::t.test(x, y, conf.level = 1 - 2 * alpha)

  expect_equal(unname(result$statistic), c(
    unname(lower_test$statistic), unname(upper_test$statistic)
  ))
  expect_equal(result$p.value, max(lower_test$p.value, upper_test$p.value))
  expect_equal(result$df, unname(lower_test$parameter))
  expect_equal(as.numeric(result$conf.int), as.numeric(interval_test$conf.int))
})

test_that("formula TOST preserves missing values for validation", {
  data <- data.frame(
    response = c(3.1, 3.4, 3.8, 2.7, 3.2, 5.0),
    group = factor(c("A", "A", "A", "B", "B", "B"))
  )
  vector_result <- pharma_tost(data$response[1:3], data$response[4:6], -2, 2)
  formula_result <- pharma_tost(response ~ group, data = data,
                                low_eqbound = -2, high_eqbound = 2)
  expect_equal(formula_result, vector_result)

  data$response[1] <- NA_real_
  expect_error(
    pharma_tost(response ~ group, data = data,
                low_eqbound = -2, high_eqbound = 2),
    "NA values"
  )
})

test_that("TOST rejects undefined variance and invalid significance levels", {
  expect_error(pharma_tost(rep(1, 3), rep(2, 4), -2, 2), "variance")
  expect_error(pharma_tost(1:4, 2:5, -2, 2, alpha = 0.5), "alpha")
  expect_error(pharma_tost(1:4, 2:5, -2, 2, alpha = 0), "alpha")
  expect_error(pharma_tost(1:4, 2:5, 2, -2), "low_eqbound")
})
