test_that("pharma_response_surface fits an lm model", {
  x1 <- 1:10
  x2 <- 11:20
  y <- x1 + x2
  fit <- pharma_response_surface(x1, x2, y)
  expect_s3_class(fit, "lm")
})
