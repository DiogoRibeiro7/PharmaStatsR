library(testthat)

# Unit tests for validate_inputs utility

test_that("validate_inputs accepts valid input", {
  df <- data.frame(x = 1:3, y = 4:6)
  expect_invisible(validate_inputs(df, y ~ x, c("x", "y")))
})

test_that("validate_inputs errors on non-data-frame", {
  expect_error(validate_inputs(list(a = 1)), "'data' must be a data frame")
})

test_that("validate_inputs errors on bad formula", {
  df <- data.frame(x = 1:3)
  expect_error(validate_inputs(df, y ~ x), "Formula uses variables not in data")
})

test_that("validate_inputs errors on missing columns", {
  df <- data.frame(x = 1:3)
  expect_error(validate_inputs(df, required_cols = "y"), "Missing required columns")
})

# Ensure key helpers invoke validate_inputs

test_that("pharma_anova validates its inputs", {
  expect_error(pharma_anova(response ~ treatment, data = list()), "'data' must be a data frame")
})

test_that("pharma_kaplan_meier validates its inputs", {
  df <- data.frame(time = 1:3, status = c(1, 0, 1))
  expect_error(pharma_kaplan_meier(survival::Surv(time, status) ~ group, df), "Formula uses variables not in data")
})

test_that("pharma_kaplan_meier errors on non-data-frame", {
  skip_if_not_installed("survival")
  expect_error(
    pharma_kaplan_meier(
      survival::Surv(time, status) ~ group,
      list(time = 1:3, status = c(1, 0, 1), group = c(1, 1, 2))
    ),
    "'data' must be a data frame"
  )
})

test_that("pharma_lmm validates its inputs", {
  df <- data.frame(response = 1:3)
  expect_error(pharma_lmm(response ~ group + (1 | subject), df), "Formula uses variables not in data")
})

test_that("pharma_lmm errors on non-data-frame", {
  skip_if_not_installed("lme4")
  expect_error(
    pharma_lmm(
      response ~ group + (1 | subject),
      list(response = 1:3, group = c(1, 0, 1), subject = 1:3)
    ),
    "'data' must be a data frame"
  )
})

test_that("pharma_competing_risks validates its inputs", {
  df <- data.frame(time = 1:3, status = c(1, 2, 0))
  expect_error(pharma_competing_risks(survival::Surv(time, status) ~ group, df), "Formula uses variables not in data")
})

test_that("pharma_competing_risks errors on non-data-frame", {
  skip_if_not_installed("cmprsk")
  expect_error(
    pharma_competing_risks(
      survival::Surv(time, status) ~ group,
      list(time = 1:3, status = c(1, 2, 0), group = c(0, 1, 1))
    ),
    "'data' must be a data frame"
  )
})

test_that("pharma_t_test.formula validates its inputs", {
  df <- data.frame(response = 1:3)
  expect_error(pharma_t_test(response ~ group, data = df), "Formula uses variables not in data")
})

test_that("pharma_t_test.formula errors on non-data-frame", {
  expect_error(
    pharma_t_test(
      response ~ group,
      data = list(response = 1:3, group = c(1, 1, 2))
    ),
    "'data' must be a data frame"
  )
})

test_that("pharma_tost.formula validates its inputs", {
  df <- data.frame(response = 1:3)
  expect_error(pharma_tost(response ~ group, data = df, -1, 1), "Formula uses variables not in data")
})

test_that("pharma_tost.formula errors on non-data-frame", {
  expect_error(
    pharma_tost(
      response ~ group,
      data = list(response = 1:3, group = c(1, 1, 2)),
      -1, 1
    ),
    "'data' must be a data frame"
  )
})
