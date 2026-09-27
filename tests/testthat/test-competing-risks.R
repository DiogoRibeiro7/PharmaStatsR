test_that("competing event codes match a direct Fine-Gray fit", {
  skip_if_not_installed("cmprsk")
  set.seed(142)
  n <- 180L
  dat <- data.frame(
    time = seq_len(n) / 10,
    status = sample(rep(0:2, each = n / 3)),
    group = factor(rep(c("control", "active"), length.out = n)),
    x = stats::rnorm(n)
  )
  matrix <- stats::model.matrix(~ group + x, dat)[, -1L, drop = FALSE]
  direct <- cmprsk::crr(dat$time, dat$status, matrix)
  wrapped <- pharma_competing_risks(
    survival::Surv(time, status) ~ group + x, dat
  )
  expect_equal(wrapped$coef, direct$coef, tolerance = 1e-8)
  expect_equal(wrapped$loglik, direct$loglik, tolerance = 1e-8)
  expect_equal(wrapped$n, n)

  # A model without an intercept must retain all indicator columns.
  matrix_no_intercept <- stats::model.matrix(~ 0 + x + I(x^2), dat)
  direct_second <- cmprsk::crr(
    dat$time, dat$status, matrix_no_intercept, failcode = 2
  )
  wrapped_second <- pharma_competing_risks(
    survival::Surv(time, status) ~ 0 + x + I(x^2), dat, failcode = 2
  )
  expect_equal(wrapped_second$coef, direct_second$coef, tolerance = 1e-8)
  expect_equal(wrapped_second$loglik, direct_second$loglik, tolerance = 1e-8)
})

test_that("competing risks rejects ambiguous or incomplete model inputs", {
  skip_if_not_installed("cmprsk")
  dat <- data.frame(
    time = seq_len(9), status = rep(0:2, 3),
    x = rep(c(0, 1, 2), 3)
  )
  formula <- survival::Surv(time, status) ~ x
  expect_error(
    pharma_competing_risks(formula, transform(dat, status = factor(status))),
    "status must be"
  )
  expect_error(
    pharma_competing_risks(formula, transform(dat, status = NA_integer_)),
    "status must be"
  )
  expect_error(
    pharma_competing_risks(formula, transform(dat, time = Inf)),
    "time must be"
  )
  expect_error(
    pharma_competing_risks(formula, transform(dat, x = NA_real_)),
    "missing values"
  )
  expect_error(
    pharma_competing_risks(formula, dat, failcode = 0, cencode = 0),
    "distinct"
  )
  expect_error(
    pharma_competing_risks(formula, dat, failcode = 7),
    "failcode must occur"
  )
  expect_error(
    pharma_competing_risks(survival::Surv(time) ~ x, dat),
    "unnamed Surv"
  )
  expect_error(
    pharma_competing_risks(survival::Surv(time, status) ~ 1, dat),
    "at least one"
  )
})
