test_that("pharma_parallel_bootstrap returns list", {
  skip_if_not_installed("future.apply")
  stat <- function(d) mean(d$response)
  res <- pharma_parallel_bootstrap(pharma_sample, stat, R = 4, plan = "sequential")
  expect_length(res, 4)
})
