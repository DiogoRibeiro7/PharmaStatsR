test_that("metafor exports report a missing backend even when installed", {
  testthat::local_mocked_bindings(
    .pharma_optional_available = function(package) package != "metafor"
  )
  expect_error(pharma_meta_analysis(yi = 1:3, vi = 1:3),
               "pharma_meta_analysis\\(\\).*install.packages\\('metafor'\\)")
  expect_error(pharma_forest_plot(list()),
               "pharma_forest_plot\\(\\).*install.packages\\('metafor'\\)")
  expect_error(pharma_funnel_plot(list()),
               "pharma_funnel_plot\\(\\).*install.packages\\('metafor'\\)")
})

test_that("pharma_network_meta_analysis validates data", {
  skip_if_not_installed("netmeta")
  expect_error(
    pharma_network_meta_analysis(TE, seTE, treat1, treat2, data = 1),
    "'data' must be a data frame"
  )
})
