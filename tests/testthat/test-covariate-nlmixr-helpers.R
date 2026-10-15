local_edition(3)

library(testthat)

test_that("the optional backend fits data containing dosing events", {
  skip_if_not_installed("nlmixr2est")
  skip_if_not_installed("nlmixr2data")

  fit <- fit_nlmixr_model(
    nlmixr2data::theo_sd, "DV", "ID", character(0)
  )

  expect_s3_class(fit, "nlmixr2FitData")
  expect_true(nrow(fit) > 0)
  expect_true(all(is.finite(fit$PRED)))
})

test_that("validate_nlmixr_inputs validates expected branches", {
  d <- data.frame(
    SubjectID = rep(1:3, each = 2),
    Time = rep(0:1, times = 3),
    DV = rnorm(6),
    WT = rnorm(6)
  )
  expect_invisible(
    PharmaStatsR:::validate_nlmixr_inputs(d, "DV", "SubjectID", "WT")
  )
  expect_error(
    PharmaStatsR:::validate_nlmixr_inputs(1, "DV", "SubjectID", "WT"),
    "`data` must be a data.frame"
  )
  expect_error(
    PharmaStatsR:::validate_nlmixr_inputs(d, "DV_MISSING", "SubjectID", "WT"),
    "Variables not found"
  )
  d_no_time <- d
  d_no_time$Time <- NULL
  expect_error(
    PharmaStatsR:::validate_nlmixr_inputs(d_no_time, "DV", "SubjectID", "WT"),
    "must contain a time column"
  )
})

test_that("prepare_nlmixr_data creates standardized columns", {
  d <- data.frame(
    SubjectID = rep(1:3, each = 2),
    Time = rep(0:1, times = 3),
    DV = rnorm(6),
    WT = rnorm(6)
  )
  expect_warning(
    out <- PharmaStatsR:::prepare_nlmixr_data(d, "DV", "SubjectID", "WT"),
    "will be ignored"
  )
  expect_true(all(c("ID", "DV", "TIME") %in% names(out)))
  expect_equal(out$ID, d$SubjectID)
  expect_equal(out$TIME, d$Time)
})
