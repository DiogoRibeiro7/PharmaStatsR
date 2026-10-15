local_edition(3)

library(testthat)

make_sample_data <- function() {
  data.frame(
    a = c(1, NA, 3),
    b = c(NA, NA, 2),
    c = c(NA_real_, NA_real_, NA_real_)
  )
}

test_that("impute_mean replaces NA with mean", {
  sample_data <- make_sample_data()
  result_mean <- suppressWarnings(impute_mean(sample_data, c("a", "b", "c")))
  expect_equal(result_mean$a[2], mean(sample_data$a, na.rm = TRUE))
  expect_equal(result_mean$b[1], mean(sample_data$b, na.rm = TRUE))
})

test_that("impute_mean leaves all-NA columns unchanged", {
  sample_data <- make_sample_data()
  result_mean <- suppressWarnings(impute_mean(sample_data, c("a", "b", "c")))
  expect_true(all(is.na(result_mean$c)))
})

test_that("impute_median replaces NA with median", {
  sample_data <- make_sample_data()
  result_median <- suppressWarnings(
    impute_median(sample_data, c("a", "b", "c"))
  )
  expect_equal(result_median$a[2], stats::median(sample_data$a, na.rm = TRUE))
  expect_equal(result_median$b[1], stats::median(sample_data$b, na.rm = TRUE))
})

test_that("impute_median leaves all-NA columns unchanged", {
  sample_data <- make_sample_data()
  result_median <- suppressWarnings(
    impute_median(sample_data, c("a", "b", "c"))
  )
  expect_true(all(is.na(result_median$c)))
})

test_that("location imputation fills NaN and preserves observations", {
  d <- data.frame(x = c(1, NA_real_, 3, NaN, 8), label = letters[1:5])
  original <- d
  mean_result <- impute_mean(d, "x")
  median_result <- impute_median(d, "x")
  expect_equal(mean_result$x, c(1, 4, 3, 4, 8))
  expect_equal(median_result$x, c(1, 3, 3, 3, 8))
  expect_identical(mean_result$label, d$label)
  expect_identical(median_result$label, d$label)
  expect_identical(d, original)
})

test_that("all-missing columns warn and constant observed columns can impute", {
  for (impute in list(impute_mean, impute_median)) {
    missing <- data.frame(x = c(NA_real_, NaN))
    expect_warning(result <- impute(missing, "x"), "contains only NA")
    expect_identical(result, missing)
    expect_equal(impute(data.frame(x = c(2, NA, 2)), "x")$x, c(2, 2, 2))
    empty <- data.frame(x = numeric(0))
    expect_no_warning(result <- impute(empty, "x"))
    expect_identical(result, empty)
  }
})
