survival_regression_fixture <- function() {
  data.frame(
    time = c(2, 4, 4, 5, 6, 7, 8, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18),
    status = c(1, 1, 0, 1, 0, 1, 1, 0, 1, 1, 0, 1, 1, 0, 1, 1, 0, 1),
    group = factor(rep(c("control", "active"), 9)),
    score = c(NA, NA, 4, 3, 0, 5, 1, 4, 2, 5, 3, 0, 4, 1, 5, 2, 0, 3),
    selected = !(seq_len(18) %in% c(2L, 17L))
  )
}

test_that("ordinary Cox fit matches a direct fit on the same subjects", {
  data <- survival_regression_fixture()
  formula <- survival::Surv(time, status) ~ group + score
  reference <- survival::coxph(
    formula, data = data, subset = selected,
    na.action = stats::na.omit, ties = "breslow"
  )
  actual <- pharma_survival_fit(
    formula, data, subset = selected,
    na.action = stats::na.omit, ties = "breslow"
  )
  included <- data[data$selected & !is.na(data$score), , drop = FALSE]

  expect_equal(stats::coef(actual), stats::coef(reference))
  expect_equal(actual$loglik, reference$loglik)
  expect_identical(actual$n, nrow(included))
  expect_identical(actual$nevent, sum(included$status))
  expect_equal(unname(actual$y), unname(reference$y))
})

test_that("Weibull AFT fit matches survreg and an exponential reference", {
  data <- survival_regression_fixture()
  formula <- survival::Surv(time, status) ~ group + score
  reference <- survival::survreg(
    formula, data = data, subset = selected,
    na.action = stats::na.omit, dist = "weibull"
  )
  actual <- pharma_parametric_survival(
    formula, data, subset = selected,
    na.action = stats::na.omit, dist = "weibull"
  )
  included <- data[data$selected & !is.na(data$score), , drop = FALSE]

  expect_equal(stats::coef(actual), stats::coef(reference))
  expect_equal(actual$scale, reference$scale)
  expect_equal(actual$loglik, reference$loglik)
  expect_length(actual$linear.predictors, nrow(included))
  expect_equal(actual$na.action, reference$na.action)

  # With complete uncensored observations, the exponential MLE mean time
  # is the sample mean. This check does not depend on a second fit.
  complete <- data.frame(time = c(1, 2, 3, 4, 6, 8), status = rep(1, 6))
  exponential <- pharma_parametric_survival(
    survival::Surv(time, status) ~ 1, complete, dist = "exponential"
  )
  expect_equal(exp(unname(stats::coef(exponential)[1])), mean(complete$time),
               tolerance = 1e-6)
  expect_equal(exponential$scale, 1)
})
