test_that("diagnostics match the fitted lm screening measures", {
  fit <- stats::lm(response ~ treatment + dose, data = pharma_sample)
  result <- pharma_model_diagnostics(fit)
  expect_named(result, c("residual", "std_resid", "cook_d",
                         "leverage", "flag"))
  expect_equal(unname(result$residual), unname(stats::residuals(fit)))
  expect_equal(unname(result$std_resid), unname(stats::rstandard(fit)))
  expect_equal(unname(result$cook_d), unname(stats::cooks.distance(fit)))
  expect_equal(unname(result$leverage), unname(stats::hatvalues(fit)))
  expected <- abs(stats::rstandard(fit)) > 3 |
    stats::cooks.distance(fit) > 4 / stats::nobs(fit)
  expect_identical(unname(result$flag), unname(expected))
})

test_that("diagnostics use fitted count for na.exclude and retain NA rows", {
  dat <- data.frame(x = seq_len(100))
  dat$y <- dat$x + sin(dat$x)
  dat$y[1:90] <- NA_real_
  fit <- stats::lm(y ~ x, data = dat, na.action = stats::na.exclude)
  result <- pharma_model_diagnostics(fit, threshold = 1000)
  expect_equal(stats::nobs(fit), 10L)
  expect_length(result$flag, 100L)
  expect_true(all(is.na(result$flag[1:90])))
  expect_identical(
    unname(result$flag),
    unname(abs(stats::rstandard(fit)) > 1000 |
             stats::cooks.distance(fit) > 4 / stats::nobs(fit))
  )
})

test_that("explicit Cook cutoff works for a binomial glm", {
  fit <- stats::glm(outcome ~ dose, family = stats::binomial(),
                    data = pharma_sample)
  result <- pharma_model_diagnostics(fit, threshold = 2,
                                     cook_cutoff = 0.25)
  expected <- abs(stats::rstandard(fit)) > 2 |
    stats::cooks.distance(fit) > 0.25
  expect_identical(unname(result$flag), unname(expected))
  expect_equal(unname(result$residual), unname(stats::residuals(fit)))
})

test_that("diagnostic inputs reject ambiguous cutoffs and multivariate fits", {
  fit <- stats::lm(response ~ dose, data = pharma_sample)
  for (bad in list(NA_real_, Inf, 0, -1, c(2, 3), "3")) {
    expect_error(pharma_model_diagnostics(fit, threshold = bad),
                 "threshold must")
    expect_error(pharma_model_diagnostics(fit, cook_cutoff = bad),
                 "cook_cutoff must")
  }
  expect_error(pharma_model_diagnostics(list()), "univariate")
  dat <- data.frame(x = 1:6, y = c(1, 2, 4, 3, 5, 6))
  multi <- stats::lm(cbind(y, y + 1) ~ x, data = dat)
  expect_error(pharma_model_diagnostics(multi), "univariate")
})
