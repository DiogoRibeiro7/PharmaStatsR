test_that("pharma_meta_analysis requires metafor", {
  skip_if(requireNamespace("metafor", quietly = TRUE), "metafor installed")
  expect_error(
    pharma_meta_analysis(yi = 1:3, vi = 1:3),
    "Package 'metafor' is required"
  )
})

test_that("pharma_network_meta_analysis validates data", {
  skip_if_not_installed("netmeta")
  expect_error(
    pharma_network_meta_analysis(TE, seTE, treat1, treat2, data = 1),
    "'data' must be a data frame"
  )
})
