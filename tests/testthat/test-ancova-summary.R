local_edition(3)

summary_reference_data <- function() {
  data.frame(
    response = c(11, 11, 13, 17, 14, 16, 20, 26),
    treatment = factor(rep(c("A", "B"), each = 4)),
    baseline = rep(0:3, 2)
  )
}

test_that("ANCOVA summary has independent lm-style numerical references", {
  fit <- pharma_ancova(response ~ treatment + baseline, summary_reference_data())
  original <- fit
  result <- summary(fit)
  expect_s3_class(result, c("summary.pharma_ancova", "summary.lm"))
  beta <- c(8.5, 6, 3)
  # Additive SSE=18, residual df=5; diag((X'X)^-1)=(19/40, 1/2, 1/10).
  se <- sqrt((18 / 5) * c(19 / 40, 1 / 2, 1 / 10))
  t <- beta / se
  expected <- cbind(beta, se, t, 2 * stats::pt(-abs(t), df = 5))
  expect_equal(unname(stats::coef(result)), unname(expected), tolerance = 1e-12)
  expect_identical(colnames(result$coefficients), c("Estimate", "Std. Error", "t value", "Pr(>|t|)"))
  expect_identical(rownames(result$coefficients), c("(Intercept)", "treatmentB", "baseline"))
  expect_equal(result$sigma, sqrt(18 / 5), tolerance = 1e-12)
  expect_equal(unname(result$df), c(3, 5, 3))
  expect_equal(unname(result$residuals), c(2.5, -0.5, -1.5, -0.5, -0.5, -1.5, -0.5, 2.5), tolerance = 1e-12)
  # Total SS=180, explained SS=162: R^2=.9, adjusted R^2=.86, F=22.5.
  expect_equal(result$r.squared, 0.9, tolerance = 1e-12)
  expect_equal(result$adj.r.squared, 0.86, tolerance = 1e-12)
  expect_equal(unname(result$fstatistic), c(22.5, 2, 5), tolerance = 1e-12)
  expect_equal(result$slope_homogeneity$F, 5, tolerance = 1e-12)
  expect_equal(result$slope_homogeneity$p.value, stats::pf(5, 1, 4, lower.tail = FALSE), tolerance = 1e-12)
  expect_equal(result$adjusted_means$adjusted_mean, c(13, 19), tolerance = 1e-12)
  expect_identical(fit, original)
})

test_that("ANCOVA summary preserves native options and stored adjustment intervals", {
  d <- summary_reference_data()
  fit <- pharma_ancova(response ~ treatment + baseline, d, conf.level = 0.9)
  result <- summary(fit, correlation = TRUE, symbolic.cor = TRUE)
  native <- summary(fit$model, correlation = TRUE, symbolic.cor = TRUE)
  for (name in names(native)) expect_identical(result[[name]], native[[name]])
  expect_identical(result$adjusted_means, fit$adjusted_means)
  expect_identical(result$slope_homogeneity, fit$slope_homogeneity)
  expect_identical(result$covariate_mean, fit$covariate_mean)
  expect_identical(result$covariate, "baseline")
  expect_identical(result$treatment, "treatment")
  expect_true(result$symbolic.cor)
})

test_that("ANCOVA summaries and printing work after saved-fit restoration", {
  fit <- pharma_ancova(response ~ treatment + baseline, summary_reference_data())
  path <- tempfile(fileext = ".rds")
  on.exit(unlink(path))
  saveRDS(fit, path)
  restored <- readRDS(path)
  result <- summary(restored, correlation = TRUE)
  expected <- summary(fit, correlation = TRUE)
  # A formula's saved environment is restored separately; compare results and
  # formula text instead of incidental local bindings in that environment.
  fields <- setdiff(names(result), "terms")
  expect_equal(result[fields], expected[fields])
  expect_identical(deparse(stats::formula(result$terms)), deparse(stats::formula(expected$terms)))
  original <- result
  printed <- capture.output(value <- withVisible(print(result, digits = 5, signif.stars = FALSE)))
  expect_false(value$visible)
  expect_identical(value$value, result)
  expect_identical(result, original)
  for (heading in c(
    "ANCOVA: additive model", "Residuals:", "Coefficients:",
    "Residual standard error:", "Multiple R-squared:", "F-statistic:",
    "Correlation of Coefficients:", "Common-slope diagnostic:",
    "Adjusted means and confidence limits at baseline = 1.5"
  )) {
    expect_true(any(grepl(heading, printed, fixed = TRUE)), info = heading)
  }
  expect_false(any(grepl("Signif. codes", printed, fixed = TRUE)))
  expect_true(any(grepl("does not establish equal slopes", printed, fixed = TRUE)))
  symbolic <- capture.output(print(summary(fit, correlation = TRUE, symbolic.cor = TRUE)))
  expect_true(any(grepl("Correlation of Coefficients:", symbolic, fixed = TRUE)))
  # A summary is itself a useful saved result, with standard coef() extraction.
  saveRDS(result, path)
  expect_identical(stats::coef(readRDS(path)), result$coefficients)
})
