test_that("pharma_dashboard returns path", {
  path <- pharma_dashboard(launch = FALSE)
  expect_true(file.exists(path))
})
