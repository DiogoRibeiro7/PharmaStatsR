test_that("pharma_pp_check errors when bayesplot is missing", {
  skip_if(requireNamespace("bayesplot", quietly = TRUE), "bayesplot installed")
  expect_error(pharma_pp_check(list()), "Package 'bayesplot' is required")
})
