test_that("pharma_pp_check requires rstanarm's stanreg method", {
  testthat::local_mocked_bindings(
    .pharma_optional_available = function(package) package != "rstanarm"
  )
  expect_error(pharma_pp_check(list()),
               "pharma_pp_check\\(\\).*install.packages\\('rstanarm'\\)")
})

test_that("pharma_pp_check requires the bayesplot generic", {
  testthat::local_mocked_bindings(
    .pharma_optional_available = function(package) package != "bayesplot"
  )
  expect_error(pharma_pp_check(list()),
               "pharma_pp_check\\(\\).*install.packages\\('bayesplot'\\)")
})
