test_that("pharma_scipy_ttest errors when reticulate is missing", {
  skip_if(requireNamespace("reticulate", quietly = TRUE), "reticulate installed")
  expect_error(pharma_scipy_ttest(1:3, 4:6), "Package 'reticulate' is required")
})

test_that("pharma_scipy_ttest returns statistics when SciPy available", {
  skip_if_not_installed("reticulate")
  skip_if_not(reticulate::py_module_available("scipy"))
  x <- c(1, 2, 3, 4)
  y <- c(2, 3, 4, 5)
  res <- pharma_scipy_ttest(x, y)
  expect_type(res$statistic, "double")
  expect_type(res$p.value, "double")
})
