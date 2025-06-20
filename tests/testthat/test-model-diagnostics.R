context("Model diagnostics")

test_that("pharma_model_diagnostics returns data frame", {
  fit <- lm(response ~ treatment + dose, data = pharma_sample)
  diag <- pharma_model_diagnostics(fit)
  expect_true(is.data.frame(diag))
  expect_true(all(c("residual", "std_resid", "cook_d", "leverage", "flag") %in% names(diag)))
})
