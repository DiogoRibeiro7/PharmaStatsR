test_that("pharma_sensitivity_analysis matches fixed Rubin components", {
  skip_if_not_installed("mice", minimum_version = "3.15.0")

  # Three completed versions of one missing treated response; no random
  # imputation or fitted backend is used to construct the expected values.
  original <- data.frame(
    treatment = rep(0:1, each = 3),
    response = c(0, 2, 4, 4, 6, NA_real_)
  )
  long <- do.call(rbind, lapply(0:3, function(index) {
    dat <- original
    if (index > 0) {
      dat$response[6] <- c(5, 7, 9)[index]
    }
    dat$.imp <- index
    dat$.id <- as.character(seq_len(nrow(dat)))
    dat
  }))
  imp <- mice::as.mids(long)
  completed <- mice::complete(imp, action = "all")
  expect_equal(unname(vapply(completed, function(dat) dat$response[6], numeric(1))),
               c(5, 7, 9))

  pooled <- pharma_sensitivity_analysis(imp, response ~ treatment)
  slope <- pooled$pooled[pooled$pooled$term == "treatment", ]
  expect_equal(nrow(slope), 1L)

  # Group-mean differences: 3, 11/3, 13/3. The residual sums of squares
  # are 10, 38/3, 62/3; with four residual df and (X'X)^-1[2, 2] = 2/3,
  # the within variances are 5/3, 19/9, 31/9. Their mean is 65/27.
  # The between variance is 4/9, giving T = 65/27 + (1 + 1/3) * 4/9 = 3.
  expect_equal(slope$estimate, 11 / 3, tolerance = 1e-8)
  expect_equal(slope$ubar, 65 / 27, tolerance = 1e-8)
  expect_equal(slope$b, 4 / 9, tolerance = 1e-8)
  expect_equal(slope$t, 3, tolerance = 1e-8)
  result <- summary(pooled)
  expect_equal(result$std.error[result$term == "treatment"], sqrt(3),
               tolerance = 1e-8)
})

test_that("pharma_sensitivity_analysis requires a mids input", {
  skip_if_not_installed("mice", minimum_version = "3.15.0")
  expect_error(
    pharma_sensitivity_analysis(list(), response ~ treatment),
    "mids_obj must be a mice mids object"
  )
})
