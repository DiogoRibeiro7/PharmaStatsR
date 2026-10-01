test_that("multistate model reports a missing mstate backend", {
  testthat::local_mocked_bindings(.pharma_mstate_available = function() FALSE)
  cox_fit <- structure(list(), class = "coxph")
  expect_error(pharma_multistate_model(cox_fit, matrix(1)),
               "install.packages\\('mstate'\\)")
})

test_that("multistate model checks Cox fit and transition matrix", {
  expect_error(pharma_multistate_model(list(), matrix(1)),
               "coxFit must be a 'coxph' object")
  skip_if_not_installed("mstate")
  cox_fit <- structure(list(), class = "coxph")
  expect_error(pharma_multistate_model(cox_fit, list()),
               "square transition matrix")
  expect_error(pharma_multistate_model(cox_fit, matrix(1:6, 2, 3)),
               "square transition matrix")
})

test_that("multistate model forwards newdata to the installed backend", {
  skip_if_not_installed("mstate")

  trans <- mstate::trans.illdeath()
  wide <- data.frame(
    illt = c(1, 1, 6, 6, 8, 9), ills = c(1, 0, 1, 1, 0, 1),
    dt = c(5, 1, 9, 7, 8, 12), ds = rep(1, 6),
    x1 = c(1, 1, 1, 0, 0, 0), x2 = 6:1
  )
  long <- mstate::msprep(
    time = c(NA, "illt", "dt"), status = c(NA, "ills", "ds"),
    data = wide, keep = c("x1", "x2"), trans = trans
  )
  long <- mstate::expand.covs(long, c("x1", "x2"))
  fit <- survival::coxph(
    survival::Surv(Tstart, Tstop, status) ~ x1.1 + x2.2 + strata(trans),
    data = long, method = "breslow"
  )
  profile <- data.frame(
    trans = 1:3, x1.1 = c(0, 0, 0), x2.2 = c(0, 1, 0), strata = 1:3
  )

  actual <- pharma_multistate_model(fit, trans, newdata = profile)
  direct <- mstate::msfit(fit, newdata = profile, trans = trans)
  expect_s3_class(actual, "msfit")
  expect_equal(actual$Haz, direct$Haz)
  expect_equal(actual$varHaz, direct$varHaz)

  without_variance <- pharma_multistate_model(
    fit, trans, newdata = profile, variance = FALSE
  )
  expect_equal(
    without_variance,
    mstate::msfit(fit, newdata = profile, variance = FALSE, trans = trans)
  )

  baseline_fit <- survival::coxph(
    survival::Surv(Tstart, Tstop, status) ~ strata(trans),
    data = long, method = "breslow"
  )
  expect_equal(
    pharma_multistate_model(baseline_fit, trans),
    mstate::msfit(baseline_fit, trans = trans)
  )
})
