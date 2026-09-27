test_that("curve-specific confidence options do not reach survdiff", {
  formula <- survival::Surv(time, status) ~ treatment
  data <- pharma_survival
  actual <- pharma_kaplan_meier(
    formula, data, conf.type = "log-log", conf.int = 0.9
  )
  curve <- survival::survfit(
    formula, data, na.action = stats::na.omit,
    conf.type = "log-log", conf.int = 0.9
  )
  test <- survival::survdiff(formula, data, na.action = stats::na.omit)
  expect_equal(actual$fit$surv, curve$surv)
  expect_equal(actual$fit$lower, curve$lower)
  expect_equal(actual$test$chisq, test$chisq)
  expect_equal(actual$test$n, test$n)
})

test_that("subset and missing value handling are shared by fit and test", {
  data <- pharma_survival
  data$status[2] <- NA_integer_
  selected <- data$subject %% 2 == 0
  complete <- data[selected, , drop = FALSE]
  formula <- survival::Surv(time, status) ~ treatment
  actual <- pharma_kaplan_meier(
    formula, data, subset = subject %% 2 == 0,
    na.action = stats::na.exclude
  )
  curve <- survival::survfit(
    formula, complete, na.action = stats::na.exclude
  )
  test <- survival::survdiff(
    formula, complete, na.action = stats::na.exclude
  )
  expect_equal(actual$fit$surv, curve$surv)
  expect_equal(actual$test$chisq, test$chisq)
  expect_equal(sum(actual$fit$n), sum(actual$test$n))
  expect_equal(sum(actual$test$n), sum(test$n))
})

test_that("curve-only mode returns a survfit object", {
  formula <- survival::Surv(time, status) ~ 1
  actual <- pharma_kaplan_meier(
    formula, pharma_survival, log_rank = FALSE, conf.type = "log-log"
  )
  expect_s3_class(actual, "survfit")
  expect_equal(
    actual$surv,
    survival::survfit(formula, pharma_survival,
                      conf.type = "log-log")$surv
  )
})

test_that("invalid controls and incompatible paired options fail", {
  formula <- survival::Surv(time, status) ~ treatment
  data <- pharma_survival
  for (bad in list(NA, 1, c(TRUE, FALSE), "TRUE")) {
    expect_error(pharma_kaplan_meier(formula, data, log_rank = bad),
                 "log_rank must")
    expect_error(pharma_kaplan_meier(formula, data, timefix = bad),
                 "timefix must")
  }
  expect_error(pharma_kaplan_meier(formula, data, subset = c(TRUE, NA)),
               "subset must")
  expect_error(pharma_kaplan_meier(formula, data, na.action = "na.omit"),
               "na.action must")
  expect_error(
    pharma_kaplan_meier(formula, data, weights = rep(1, nrow(data))),
    "cannot be paired"
  )
  expect_error(
    pharma_kaplan_meier(formula, data, stype = 2),
    "alternative estimators"
  )
  expect_error(
    pharma_kaplan_meier(
      survival::Surv(time, factor(status)) ~ treatment, data,
      log_rank = FALSE
    ),
    "right-censored single-event"
  )
})
