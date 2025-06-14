test_that("pharma_t_test returns htest", {
  res <- pharma_t_test(rnorm(10), rnorm(10))
  expect_s3_class(res, "htest")
})

test_that("pharma_chisq_test returns htest", {
  tbl <- matrix(c(10,5,6,9), nrow = 2)
  res <- pharma_chisq_test(tbl)
  expect_s3_class(res, "htest")
})

test_that("pharma_anova returns aov", {
  res <- pharma_anova(response ~ treatment, data = pharma_sample)
  expect_s3_class(res, "aov")
})

test_that("pharma_logistic_regression returns glm", {
  res <- pharma_logistic_regression(outcome ~ dose, data = pharma_sample)
  expect_s3_class(res, "glm")
})

test_that("pharma_sample is a data.frame", {
  expect_true(is.data.frame(pharma_sample))
  expect_equal(nrow(pharma_sample), 20)
})

test_that("pharma_crossover is a data.frame", {
  expect_true(is.data.frame(pharma_crossover))
  expect_equal(nrow(pharma_crossover), 20)
})
