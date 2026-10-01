test_that("meta-regression reports a missing optional backend", {
  testthat::local_mocked_bindings(.pharma_metafor_available = function() FALSE)

  expect_error(
    pharma_meta_regression(c(0.1, 0.2), c(0.04, 0.05), cbind(dose = 1:2)),
    "install.packages\\('metafor'\\)"
  )
})

test_that("meta-regression validates moderator alignment and method", {
  skip_if_not_installed("metafor")
  yi <- c(0.1, 0.2, 0.3, 0.4)
  vi <- rep(0.04, 4)

  expect_error(pharma_meta_regression(yi, vi[-1], cbind(dose = 1:4)),
               "same length")
  expect_error(pharma_meta_regression(yi, vi, cbind(dose = 1:3)),
               "one row per effect size")
  expect_error(pharma_meta_regression(yi, vi, matrix(NA_real_, 4, 1)),
               "finite numeric matrix")
  expect_error(pharma_meta_regression(yi, vi, matrix(1, 4, 0)),
               "at least one column")
  expect_error(pharma_meta_regression(yi, vi, ~ 1:4, method = NA_character_),
               "nonempty character scalar")
  expect_error(pharma_meta_regression(yi, vi, yi ~ dose),
               "one-sided formula")
})

test_that("fixed-effects moderator coefficients match weighted regression", {
  skip_if_not_installed("metafor")
  yi <- c(-0.3, 0.2, 0.4, 0.1, 0.7, 0.9)
  vi <- c(0.06, 0.04, 0.05, 0.03, 0.08, 0.04)
  mods <- cbind(dose = 1:6)

  fit <- pharma_meta_regression(yi, vi, mods, method = "FE")
  design <- cbind(intercept = 1, dose = mods[, "dose"])
  # The fixed-effects fit is weighted least squares with weights 1 / vi.
  information <- crossprod(design, design / vi)
  beta <- solve(information, crossprod(design, yi / vi))
  se <- sqrt(diag(solve(information)))

  expect_s3_class(fit, "rma")
  expect_identical(fit$method, "FE")
  expect_equal(as.numeric(fit$b), as.numeric(beta), tolerance = 1e-12)
  expect_equal(as.numeric(fit$se), as.numeric(se), tolerance = 1e-12)
})

test_that("formula and REML model match the metafor backend", {
  skip_if_not_installed("metafor")
  yi <- c(-0.3, 0.2, 0.4, 0.1, 0.7, 0.9)
  vi <- c(0.06, 0.04, 0.05, 0.03, 0.08, 0.04)
  studies <- data.frame(dose = 1:6)

  fit <- pharma_meta_regression(yi, vi, mods = ~ dose, data = studies)
  direct <- metafor::rma(yi = yi, vi = vi, mods = ~ dose, data = studies,
                         method = "REML")
  expect_identical(fit$method, "REML")
  expect_equal(fit$b, direct$b, tolerance = 1e-12)
  expect_equal(fit$se, direct$se, tolerance = 1e-12)
  expect_equal(fit$tau2, direct$tau2, tolerance = 1e-12)
})
