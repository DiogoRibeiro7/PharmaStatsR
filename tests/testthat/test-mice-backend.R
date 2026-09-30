test_that("imputation and pooling report a missing mice backend", {
  testthat::local_mocked_bindings(.pharma_mice_available = function() FALSE)

  expect_error(
    pharma_mice_impute(data.frame(response = c(1, NA_real_))),
    "pharma_mice_impute\\(\\).*install.packages\\('mice'\\)"
  )
  expect_error(
    pharma_sensitivity_analysis(NULL, response ~ treatment),
    "pharma_sensitivity_analysis\\(\\).*install.packages\\('mice'\\)"
  )
})

test_that("imputation returns completed datasets with no missing response", {
  skip_if_not_installed("mice", minimum_version = "3.15.0")

  dat <- pharma_sample
  dat$response[1] <- NA_real_
  imp <- pharma_mice_impute(dat, m = 2, maxit = 1, seed = 41)

  expect_s3_class(imp, "mids")
  expect_equal(imp$m, 2)
  expect_false(anyNA(mice::complete(imp, action = 1)$response))
  expect_false(anyNA(mice::complete(imp, action = 2)$response))
})

test_that("pooled lm and glm agree with direct mice analysis", {
  skip_if_not_installed("mice", minimum_version = "3.15.0")

  dat <- pharma_sample
  dat$response[1] <- NA_real_
  imp <- pharma_mice_impute(dat, m = 2, maxit = 1, seed = 41)

  linear <- pharma_sensitivity_analysis(imp, response ~ treatment)
  linear_reference <- mice::pool(with(imp, stats::lm(response ~ treatment)))
  expect_s3_class(linear, "mipo")
  expect_equal(summary(linear), summary(linear_reference), tolerance = 1e-8)

  gaussian <- pharma_sensitivity_analysis(
    imp, response ~ treatment, family = stats::gaussian()
  )
  gaussian_reference <- mice::pool(with(
    imp, stats::glm(response ~ treatment, family = stats::gaussian())
  ))
  expect_s3_class(gaussian, "mipo")
  expect_equal(summary(gaussian), summary(gaussian_reference), tolerance = 1e-8)
})
