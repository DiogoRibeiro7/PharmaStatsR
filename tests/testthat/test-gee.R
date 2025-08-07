test_that("pharma_gee validates data argument", {
  skip_if_not_installed("geepack")
  expect_error(
    pharma_gee(response ~ condition, id = pharma_repeated$subject, data = 1),
    "'data' must be a data frame"
  )
})

test_that("pharma_gee requires geepack", {
  skip_if(requireNamespace("geepack", quietly = TRUE), "geepack installed")
  expect_error(
    pharma_gee(response ~ condition, id = pharma_repeated$subject, data = pharma_repeated),
    "Package 'geepack' is required"
  )
})
