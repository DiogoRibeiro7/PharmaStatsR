test_that("interim dashboard path exists", {
  p <- pharma_interim_dashboard(launch = FALSE)
  expect_true(file.exists(p))
})
