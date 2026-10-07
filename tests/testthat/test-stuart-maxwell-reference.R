stuart_maxwell_reference_table <- function() {
  matrix(c(20,8,2, 2,15,5, 1,3,14), 3, byrow=TRUE)
}

test_that("Stuart-Maxwell matches independent marginal quadratic form", {
  x <- stuart_maxwell_reference_table()
  differences <- c(7,-4,-3)
  covariance <- matrix(c(13,-10,-3, -10,18,-8, -3,-8,11), 3, byrow=TRUE)
  d <- c(7,-4)
  v <- matrix(c(13,-10,-10,18),2,byrow=TRUE)
  expected <- as.numeric(crossprod(d, solve(v,d)))
  expect_equal(expected, 265/67, tolerance=1e-12)
  actual <- pharma_stuart_maxwell_test(x)
  expect_equal(actual$marginal.differences, differences, tolerance=0)
  expect_equal(actual$covariance, covariance, tolerance=0)
  expect_equal(unname(actual$statistic), 265/67, tolerance=1e-12)
  expect_equal(unname(actual$parameter), 2, tolerance=0)
  expect_equal(actual$p.value, stats::pchisq(265/67,2,lower.tail=FALSE), tolerance=1e-15)
})

test_that("Stuart-Maxwell is invariant to simultaneous category permutation", {
  x <- stuart_maxwell_reference_table()
  base <- pharma_stuart_maxwell_test(x)
  p <- c(3,1,2)
  perm <- pharma_stuart_maxwell_test(x[p,p,drop=FALSE])
  expect_equal(perm$statistic, base$statistic, tolerance=1e-12)
  expect_equal(perm$p.value, base$p.value, tolerance=1e-15)
})

test_that("Stuart-Maxwell returns zero for symmetric margins", {
  x <- matrix(c(10,2,1, 2,12,3, 1,3,8),3,byrow=TRUE)
  result <- pharma_stuart_maxwell_test(x)
  expect_equal(result$marginal.differences, c(0,0,0), tolerance=0)
  expect_equal(unname(result$statistic), 0, tolerance=0)
  expect_equal(result$p.value, 1, tolerance=0)
})

test_that("Stuart-Maxwell rejects malformed tables", {
  expect_error(pharma_stuart_maxwell_test(matrix(1:4,2,2)), "K >= 3")
  expect_error(pharma_stuart_maxwell_test(matrix(1:12,3,4)), "square")
  bad <- stuart_maxwell_reference_table(); bad[1,1] <- -1
  expect_error(pharma_stuart_maxwell_test(bad), "nonnegative whole-number")
  bad <- stuart_maxwell_reference_table(); bad[1,2] <- 1.5
  expect_error(pharma_stuart_maxwell_test(bad), "whole-number")
  empty <- matrix(c(5,1,0,1,5,0,0,0,0),3,byrow=TRUE)
  expect_error(pharma_stuart_maxwell_test(empty), "Every category")
})
