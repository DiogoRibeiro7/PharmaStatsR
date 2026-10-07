ancova_reference_data <- function() {
  x <- rep(0:3, 2)
  treatment <- factor(rep(c("A", "B"), each = 4), levels = c("A", "B"))
  residual <- rep(c(1, -1, -1, 1), 2)
  response <- c(10 + 2 * (0:3), 13 + 4 * (0:3)) + residual
  data.frame(response = response, treatment = treatment, baseline = x)
}

test_that("ANCOVA reproduces independent additive and interaction targets", {
  data <- ancova_reference_data()
  result <- pharma_ancova(response ~ treatment + baseline, data)

  expect_s3_class(result, "pharma_ancova")
  expect_equal(
    unname(stats::coef(result$model)),
    c(8.5, 6, 3),
    tolerance = 1e-12
  )
  expect_equal(sum(stats::residuals(result$model)^2), 18, tolerance = 1e-12)
  expect_equal(stats::df.residual(result$model), 5)

  expect_equal(
    unname(stats::coef(result$interaction_model)),
    c(10, 3, 2, 2),
    tolerance = 1e-12
  )
  expect_equal(
    sum(stats::residuals(result$interaction_model)^2),
    8,
    tolerance = 1e-12
  )
  expect_equal(stats::df.residual(result$interaction_model), 4)

  expect_equal(result$slope_homogeneity$df1, 1)
  expect_equal(result$slope_homogeneity$df2, 4)
  expect_equal(result$slope_homogeneity$F, 5, tolerance = 1e-12)
  expect_equal(
    result$slope_homogeneity$p.value,
    stats::pf(5, 1, 4, lower.tail = FALSE),
    tolerance = 1e-12
  )
})

test_that("ANCOVA adjusted means match independent group-mean targets", {
  result <- pharma_ancova(
    response ~ treatment + baseline,
    ancova_reference_data(),
    conf.level = 0.95
  )

  expected_mean <- c(13, 19)
  expected_se <- sqrt((18 / 5) / 4)
  half_width <- stats::qt(0.975, df = 5) * expected_se

  expect_equal(result$covariate_mean, 1.5, tolerance = 0)
  expect_identical(result$adjusted_means$treatment, c("A", "B"))
  expect_equal(result$adjusted_means$covariate, c(1.5, 1.5), tolerance = 0)
  expect_equal(result$adjusted_means$adjusted_mean, expected_mean,
               tolerance = 1e-12)
  expect_equal(result$adjusted_means$conf.low,
               expected_mean - half_width, tolerance = 1e-10)
  expect_equal(result$adjusted_means$conf.high,
               expected_mean + half_width, tolerance = 1e-10)
})

test_that("ANCOVA respects response scaling and covariate translation", {
  data <- ancova_reference_data()
  base <- pharma_ancova(response ~ treatment + baseline, data)

  scaled <- data
  scaled$response <- 7 - 2 * scaled$response
  scaled_fit <- pharma_ancova(response ~ treatment + baseline, scaled)
  expect_equal(
    unname(stats::coef(scaled_fit$model)),
    c(-10, -12, -6),
    tolerance = 1e-12
  )
  expect_equal(
    scaled_fit$adjusted_means$adjusted_mean,
    7 - 2 * base$adjusted_means$adjusted_mean,
    tolerance = 1e-12
  )
  expect_equal(
    scaled_fit$slope_homogeneity$F,
    base$slope_homogeneity$F,
    tolerance = 1e-12
  )

  shifted <- data
  shifted$baseline <- shifted$baseline + 10
  shifted_fit <- pharma_ancova(response ~ treatment + baseline, shifted)
  expect_equal(
    unname(stats::coef(shifted_fit$model)),
    c(-21.5, 6, 3),
    tolerance = 1e-12
  )
  expect_equal(
    shifted_fit$adjusted_means$adjusted_mean,
    base$adjusted_means$adjusted_mean,
    tolerance = 1e-12
  )
  expect_equal(
    shifted_fit$slope_homogeneity$F,
    base$slope_homogeneity$F,
    tolerance = 1e-12
  )
})

test_that("ANCOVA rejects unsupported designs before fitting", {
  data <- ancova_reference_data()

  expect_error(
    pharma_ancova(response ~ treatment * baseline, data),
    "requires response ~ treatment \+ covariate"
  )
  expect_error(
    pharma_ancova(response ~ baseline + I(baseline^2), data),
    "direct column names|categorical treatment"
  )
  bad <- data
  bad$response[1] <- NA_real_
  expect_error(pharma_ancova(response ~ treatment + baseline, bad), "NA values")

  bad <- data
  bad$baseline <- 1
  expect_error(
    pharma_ancova(response ~ treatment + baseline, bad),
    "at least two distinct"
  )
  expect_error(
    pharma_ancova(response ~ treatment + baseline, data, conf.level = 1),
    "strictly between 0 and 1"
  )
})
