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

test_that("pharma_network_meta_analysis requires netmeta", {
  skip_if(requireNamespace("netmeta", quietly = TRUE), "netmeta installed")
  df <- data.frame(
    treat1 = c("A", "B"),
    treat2 = c("B", "A"),
    TE = c(0.1, -0.1),
    seTE = c(0.1, 0.1)
  )
  expect_error(
    pharma_network_meta_analysis(TE, seTE, treat1, treat2, data = df),
    "Package 'netmeta' is required"
  )
})
