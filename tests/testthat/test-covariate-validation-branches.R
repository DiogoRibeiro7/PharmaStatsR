local_edition(3)

library(testthat)

test_that("fit_covariate_model handles validation branches", {
  d <- data.frame(
    SubjectID = rep(1:4, each = 2),
    Time = rep(0:1, times = 4),
    DV = rnorm(8)
  )
  expect_error(
    fit_covariate_model(1, "DV", "SubjectID", "Time"),
    "`data` must be a data.frame"
  )
  expect_error(
    fit_covariate_model(d, "MISSING", "SubjectID", "Time"),
    "Variables not found"
  )
  m <- fit_covariate_model(d, "DV", "SubjectID", character(0))
  expect_s3_class(m, "lme")
})

test_that("prepare_model_matrix handles validation branches", {
  d <- data.frame(x = 1:3)
  expect_error(prepare_model_matrix(1, "x"), "`data` must be a data.frame")
  expect_error(prepare_model_matrix(d, "y"), "Covariates not found")
})

test_that("validate_data_schema handles error branches", {
  expect_error(validate_data_schema(1), "`data` must be a data.frame")
  d <- data.frame(SubjectID = 1L, Time = 0, DV = 1.2)
  expect_error(validate_data_schema(d), "No covariate columns found")
  d2 <- data.frame(SubjectID = "1", Time = 0, DV = 1.2, WT = 70)
  expect_error(
    validate_data_schema(d2),
    "`SubjectID` must be integer",
    fixed = TRUE
  )
})

test_that("center_scale handles validation branches", {
  d <- data.frame(a = 1:3, b = c("x", "y", "z"))
  expect_error(center_scale(1, "a"), "`data` must be a data.frame")
  expect_error(center_scale(d, "missing"), "Variables not found")
  expect_error(center_scale(d, "b"), "must be numeric")
})

test_that("screening functions validate inputs", {
  d <- data.frame(DV = rnorm(10), x1 = rnorm(10), SubjectID = 1:10)
  expect_error(
    screen_covariates_lasso(1, "DV", "x1"),
    "`data` must be a data.frame"
  )
  expect_error(
    screen_covariates_stepwise(d, "DV", "id_missing", "x1"),
    "`id` column not found"
  )
  expect_error(
    screen_covariates_bayesian(d, "DV", "x_missing"),
    "Covariates not found"
  )
  expect_error(
    screen_covariates_bayesian(d, "DV", "x1", min_bf = -1),
    "`min_bf` must be a positive number"
  )
})

test_that("reshape_timevarying handles error branches", {
  d <- data.frame(id = 1:2, z = 1:2)
  expect_error(reshape_timevarying(1, "WT"), "`data` must be a data.frame")
  expect_error(
    reshape_timevarying(d, 1),
    "`covariates` must be a character vector"
  )
  expect_error(
    reshape_timevarying(d, "WT", id = "SubjectID"),
    "ID column 'SubjectID' not found"
  )
  expect_error(
    reshape_timevarying(d, "WT", id = "id"),
    "No time-varying covariate columns found"
  )
})

test_that("plot helpers handle error branches", {
  d <- data.frame(Time = 1:3)
  expect_error(plot_obs_vs_pred(NULL, 1), "`data` must be a data.frame")
  expect_error(plot_obs_vs_pred(NULL, d), "'DV' column")

  fake <- list(data = data.frame(X = 1:3))
  class(fake) <- "fake_model"
  expect_error(
    plot_residuals(fake),
    "model$data must contain 'Time' column",
    fixed = TRUE
  )

  d2 <- data.frame(Time = c(1, 1, 1), DV = c(1, 2, 3))
  class(fake) <- "lme"
  expect_error(plot_vpc(fake, 1), "`data` must be a data.frame")
  expect_error(plot_vpc(fake, data.frame(Time = 1:3)), "'Time' and 'DV'")
  # Trigger unique-breaks guard via single unique time
  local_mocked_bindings(
    predict = function(...) rep(1, nrow(d2)),
    .package = "stats"
  )
  expect_error(plot_vpc(fake, d2, bins = 5), "at least 2 unique values")
})

test_that("report and optional wrappers handle validation branches", {
  d <- data.frame(
    SubjectID = rep(1:4, each = 2),
    Time = rep(0:1, times = 4),
    DV = rnorm(8)
  )
  m <- fit_covariate_model(d, "DV", "SubjectID", "Time")
  expect_error(generate_report(m, d, output_format = "docx"))

  if (requireNamespace("nlmixr2est", quietly = TRUE)) {
    expect_error(
      fit_nlmixr_model(d, "DV_MISSING", "SubjectID", "Time"),
      "Variables not found"
    )
  } else {
    expect_error(
      fit_nlmixr_model(1, "DV", "SubjectID", "Time"),
      "`data` must be a data.frame"
    )
    expect_error(
      fit_nlmixr_model(d, "DV_MISSING", "SubjectID", "Time"),
      "Variables not found"
    )
    d_no_time <- d
    d_no_time$Time <- NULL
    expect_error(
      fit_nlmixr_model(d_no_time, "DV", "SubjectID", character(0)),
      "must contain a time column"
    )
    expect_error(
      fit_nlmixr_model(d, "DV", "SubjectID", "Time"),
      "Package 'nlmixr2est' is required"
    )
  }
})
