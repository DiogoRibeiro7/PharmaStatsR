# Independent deterministic imputation arithmetic: docs/missing-data.md.
# Expected completed values are derived from observed-column means, not from
# a second mice::mice() call.
mean_imputation_reference_data <- function() {
  data.frame(
    id = 1:6,
    x = c(1, NA, 3, 5, NA, 7),
    y = c(2, 4, NA, 8, 10, NA)
  )
}

mean_imputation_reference_spec <- function(names) {
  method <- setNames(rep("", length(names)), names)
  method[c("x", "y")] <- "mean"
  predictor_matrix <- matrix(
    0, nrow = length(names), ncol = length(names),
    dimnames = list(names, names)
  )
  list(method = method, predictorMatrix = predictor_matrix)
}

test_that("mean imputation matches independent observed-column targets", {
  skip_if_not_installed("mice", minimum_version = "3.15.0")

  data <- mean_imputation_reference_data()
  spec <- mean_imputation_reference_spec(names(data))
  actual <- pharma_mice_impute(
    data, m = 3, maxit = 1,
    method = spec$method, predictorMatrix = spec$predictorMatrix,
    seed = 153
  )

  expect_s3_class(actual, "mids")
  expect_equal(actual$m, 3, tolerance = 0)
  expect_equal(actual$iteration, 1, tolerance = 0)
  expect_identical(actual$method, spec$method)
  expect_equal(actual$predictorMatrix, spec$predictorMatrix, tolerance = 0)

  expect_equal(unname(as.matrix(actual$imp$x)), matrix(4, nrow = 2, ncol = 3),
    tolerance = 0
  )
  expect_equal(unname(as.matrix(actual$imp$y)), matrix(6, nrow = 2, ncol = 3),
    tolerance = 0
  )
  expect_identical(rownames(actual$imp$x), c("2", "5"))
  expect_identical(rownames(actual$imp$y), c("3", "6"))

  expected <- data.frame(
    id = 1:6,
    x = c(1, 4, 3, 5, 4, 7),
    y = c(2, 4, 6, 8, 10, 6)
  )
  for (i in seq_len(3L)) {
    completed <- mice::complete(actual, action = i)
    expect_equal(completed, expected, tolerance = 0)
    expect_identical(completed$id, data$id)
    expect_equal(completed$x[!is.na(data$x)], data$x[!is.na(data$x)],
      tolerance = 0
    )
    expect_equal(completed$y[!is.na(data$y)], data$y[!is.na(data$y)],
      tolerance = 0
    )
  }
})

test_that("mean imputation is invariant to row order by row identity", {
  skip_if_not_installed("mice", minimum_version = "3.15.0")

  original <- mean_imputation_reference_data()
  order <- c(6, 2, 5, 1, 4, 3)
  data <- original[order, ]
  spec <- mean_imputation_reference_spec(names(data))
  actual <- pharma_mice_impute(
    data, m = 2, maxit = 1,
    method = spec$method, predictorMatrix = spec$predictorMatrix,
    seed = 7
  )
  completed <- mice::complete(actual, action = 1)

  expected_x <- c(1, 4, 3, 5, 4, 7)
  expected_y <- c(2, 4, 6, 8, 10, 6)
  expect_equal(completed$x, expected_x[completed$id], tolerance = 0)
  expect_equal(completed$y, expected_y[completed$id], tolerance = 0)
  expect_identical(completed$id, original$id[order])
})

test_that("affine transformations carry through deterministic mean targets", {
  skip_if_not_installed("mice", minimum_version = "3.15.0")

  data <- mean_imputation_reference_data()
  data$x <- 10 + 2 * data$x
  data$y <- 5 - 3 * data$y
  spec <- mean_imputation_reference_spec(names(data))

  actual <- pharma_mice_impute(
    data, m = 2, maxit = 1,
    method = spec$method, predictorMatrix = spec$predictorMatrix,
    seed = 99
  )

  expect_equal(unname(as.matrix(actual$imp$x)), matrix(18, 2, 2), tolerance = 0)
  expect_equal(unname(as.matrix(actual$imp$y)), matrix(-13, 2, 2), tolerance = 0)

  completed <- mice::complete(actual, action = 1)
  expect_equal(completed$x, c(12, 18, 16, 20, 18, 24), tolerance = 0)
  expect_equal(completed$y, c(-1, -7, -13, -19, -25, -13), tolerance = 0)
})

test_that("deterministic mean reference does not depend on the random seed", {
  skip_if_not_installed("mice", minimum_version = "3.15.0")

  data <- mean_imputation_reference_data()
  spec <- mean_imputation_reference_spec(names(data))
  fit <- function(seed) pharma_mice_impute(
    data, m = 2, maxit = 1,
    method = spec$method, predictorMatrix = spec$predictorMatrix,
    seed = seed
  )

  one <- fit(1)
  two <- fit(999)
  expect_equal(one$imp$x, two$imp$x, tolerance = 0)
  expect_equal(one$imp$y, two$imp$y, tolerance = 0)
  expect_equal(mice::complete(one, 1), mice::complete(two, 1), tolerance = 0)
})
