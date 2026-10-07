cochran_q_reference_matrix <- function() {
  matrix(c(
    1,1,1,
    1,1,0,
    1,0,0,
    1,0,0,
    0,1,0,
    0,0,0
  ), nrow = 6, byrow = TRUE, dimnames = list(NULL, c("A","B","C")))
}

test_that("Cochran Q matches independent subject and condition totals", {
  x <- cochran_q_reference_matrix()
  condition_totals <- colSums(x)
  subject_totals <- rowSums(x)
  expect_equal(condition_totals, c(A=4,B=3,C=1), tolerance = 0)
  expect_equal(subject_totals, c(3,2,1,1,1,0), tolerance = 0)
  numerator <- 2 * (3 * sum(condition_totals^2) - 8^2)
  denominator <- 3 * 8 - sum(subject_totals^2)
  expect_equal(numerator, 28, tolerance = 0)
  expect_equal(denominator, 8, tolerance = 0)
  actual <- pharma_cochran_q_test(x)
  expect_equal(unname(actual$statistic), 3.5, tolerance = 0)
  expect_equal(unname(actual$parameter), 2, tolerance = 0)
  expect_equal(actual$p.value, stats::pchisq(3.5, 2, lower.tail = FALSE), tolerance = 1e-15)
})

test_that("Cochran Q is invariant to condition permutation", {
  x <- cochran_q_reference_matrix()
  base <- pharma_cochran_q_test(x)
  permuted <- pharma_cochran_q_test(x[, c(3,1,2), drop=FALSE])
  expect_equal(permuted$statistic, base$statistic, tolerance = 0)
  expect_equal(permuted$p.value, base$p.value, tolerance = 0)
})

test_that("Cochran Q returns zero for identical conditions", {
  v <- c(1,0,1,1,0,0)
  result <- pharma_cochran_q_test(cbind(A=v,B=v,C=v))
  expect_equal(unname(result$statistic), 0, tolerance = 0)
  expect_equal(result$p.value, 1, tolerance = 0)
})

test_that("two-condition Cochran Q equals uncorrected McNemar", {
  x <- rbind(c(1,0),c(1,0),c(1,0),c(0,1),c(1,1),c(0,0))
  q <- pharma_cochran_q_test(x)
  m <- pharma_mcnemar_test(matrix(c(1,3,1,1),2,byrow=TRUE), correct=FALSE)
  expect_equal(unname(q$statistic), unname(m$statistic), tolerance = 0)
  expect_equal(q$p.value, m$p.value, tolerance = 0)
})

test_that("Cochran Q rejects incomplete and nonbinary inputs", {
  expect_error(pharma_cochran_q_test(1:6), "subject-by-condition")
  expect_error(pharma_cochran_q_test(matrix(1,nrow=3)), "at least two")
  bad <- cochran_q_reference_matrix(); bad[1,1] <- 2
  expect_error(pharma_cochran_q_test(bad), "binary 0/1")
  bad <- cochran_q_reference_matrix(); bad[1,1] <- NA_real_
  expect_error(pharma_cochran_q_test(bad), "complete binary")
})
