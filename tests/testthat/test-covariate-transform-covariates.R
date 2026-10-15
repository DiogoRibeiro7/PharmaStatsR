local_edition(3)

library(testthat)

make_sample_data <- function() {
  data.frame(
    wt = c(60, 70, 80),
    age = c(30, 40, 50)
  )
}

# Check means and sds stored in params
test_that("center_scale records means and sds", {
  sample_data <- make_sample_data()
  result <- center_scale(sample_data, c("wt", "age"))
  expect_equal(
    result$params$mean,
    c(mean(sample_data$wt), mean(sample_data$age))
  )
  expect_equal(result$params$sd, c(sd(sample_data$wt), sd(sample_data$age)))
})

# Check centered and scaled values have mean 0 and sd 1
test_that("center_scale transforms data correctly", {
  sample_data <- make_sample_data()
  result <- center_scale(sample_data, c("wt", "age"))
  scaled <- result$data
  expect_equal(unname(round(colMeans(scaled), 8)), c(0, 0))
  expect_equal(unname(round(apply(scaled, 2, sd), 8)), c(1, 1))
})

test_that("scaling preserves missing values and unselected columns", {
  d <- data.frame(
    x = c(1, NA_real_, 3, NaN, 5),
    group = factor(c("a", "b", "a", "b", "a"))
  )
  original <- d
  result <- center_scale(d, "x")
  expect_equal(result$data$x[c(1, 3, 5)], c(-1, 0, 1))
  expect_identical(result$data$x[c(2, 4)], c(NA_real_, NaN))
  expect_identical(result$data$group, d$group)
  expect_equal(result$params$mean, 3)
  expect_equal(result$params$sd, 2)
  expect_identical(d, original)
})

test_that("unestimable scales fail instead of returning invalid values", {
  for (column in list(numeric(0), c(NA_real_, NaN), c(7, NA_real_))) {
    expect_error(
      center_scale(data.frame(x = column), "x"),
      "at least two observed values"
    )
  }
  for (column in list(c(2, 2, NA_real_), c(1e200, 2e200))) {
    expect_error(
      center_scale(data.frame(x = column), "x"),
      "positive, finite standard deviation"
    )
  }
})
