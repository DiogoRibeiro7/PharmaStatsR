library(testthat)

# Edge cases for pharma_t_test
test_that("pharma_t_test handles edge cases", {
  expect_warning(pharma_t_test(c(1,2,3,1e10), c(1,2,3,4)), "extreme", fixed = FALSE)
  res <- pharma_t_test(rep(5, 10), rep(5, 10))
  expect_equal(res$p.value, 1)
  res2 <- pharma_t_test(rep(5, 100), rep(5.0001, 100))
  expect_true(res2$p.value > 0.05)
  equal_var <- pharma_t_test(rnorm(30, sd = 1), rnorm(30, sd = 1), var.equal = TRUE)
  unequal_var <- pharma_t_test(rnorm(30, sd = 1), rnorm(30, sd = 10), var.equal = FALSE)
  expect_equal(equal_var$parameter, 58)
  expect_true(unequal_var$parameter < 58)
})
