test_that("pharma_t_test returns htest", {
  res <- pharma_t_test(rnorm(10), rnorm(10))
  expect_s3_class(res, "htest")
})

test_that("pharma_chisq_test returns htest", {
  tbl <- matrix(c(10,5,6,9), nrow = 2)
  res <- pharma_chisq_test(tbl)
  expect_s3_class(res, "htest")
})
