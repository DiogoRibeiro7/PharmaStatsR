local_edition(3)

library(testthat)

make_ml_data <- function() {
  data.frame(
    a = c(1, NA, 3, 4, NA),
    b = c(10, 11, 12, 13, 14),
    grp = c("x", "x", "y", "y", "y"),
    stringsAsFactors = FALSE
  )
}

test_that("impute_ml imputes numeric targets", {
  d <- make_ml_data()
  out <- impute_ml(d, "a", k = 2)
  expect_true(all(!is.na(out$a)))
  expect_true(is.numeric(out$a))
})

test_that("impute_ml imputes non-numeric targets by mode", {
  d <- make_ml_data()
  d$grp[2] <- NA
  out <- impute_ml(d, "grp", k = 2)
  expect_true(!is.na(out$grp[2]))
  expect_true(out$grp[2] %in% c("x", "y"))
})

test_that("impute_ml validates k and variable names", {
  d <- make_ml_data()
  expect_error(impute_ml(d, "missing_col"), "Variables not found")
  expect_error(impute_ml(d, "a", k = 0), "`k` must be a positive integer")
  expect_error(impute_ml(d, "a", k = 2.5), "`k` must be a positive integer")
})

test_that("impute_ml leaves all-NA columns unchanged with warning", {
  d <- make_ml_data()
  d$all_na <- NA_real_
  expect_warning(out <- impute_ml(d, "all_na"), "contains only NA")
  expect_true(all(is.na(out$all_na)))
})

test_that("nearest neighbors are stable at large and tiny numeric scales", {
  for (scale in c(1, 1e200, 1e-200)) {
    d <- data.frame(y = c(100, 10, NA), x = c(2, 1, 0) * scale)
    expect_equal(impute_ml(d, "y", k = 1)$y, c(100, 10, 10))
  }
  # The geometry uses every predictor, not only the largest coordinate.
  d <- data.frame(
    y = c(100, 10, NA), x1 = c(4, 0, 0), x2 = c(3, 4, 0)
  )
  expect_equal(impute_ml(d, "y", k = 1)$y[3], 10)
  d$x1[2] <- 0
  d$x2[2] <- 0
  expect_equal(impute_ml(d, "y", k = 1)$y[3], 10)
})

test_that("unrepresentable distances request rescaling", {
  d <- data.frame(y = c(1, NA), x = c(-1e308, 1e308))
  expect_error(impute_ml(d, "y", k = 1), "rescale numeric predictors")
  d <- data.frame(y = c(1, NA), matrix(rep(c(1e308, 0), 4), nrow = 2))
  expect_error(impute_ml(d, "y", k = 1), "rescale numeric predictors")
})

test_that("k is finite and uses donor count without integer overflow", {
  d <- data.frame(y = c(1, NA, 3), x = c(0, 1, 2))
  for (k in list(Inf, -Inf, NA_real_, NaN, "2", 1 + 1i, c(1, 2))) {
    expect_error(impute_ml(d, "y", k = k), "must be a positive integer")
  }
  expect_equal(impute_ml(d, "y", k = 1e20)$y, c(1, 2, 3))
})

test_that("infinite and unsupported predictors are rejected", {
  d <- data.frame(y = c(1, NA, 3), x = c(1, Inf, 3))
  expect_error(impute_ml(d, "y"), "Variable 'x' contains infinite values")
  d$x <- I(matrix(1:6, nrow = 3))
  expect_error(impute_ml(d, "y"), "numeric, logical, character, or factor")
  d$x <- I(list(1, 2, 3))
  expect_error(impute_ml(d, "y"), "numeric, logical, character, or factor")
})

test_that("categorical targets preserve types, levels, and stable ties", {
  d <- data.frame(
    y = factor(c("b", NA, "a"), levels = c("a", "b", "unused")),
    x = c(0, 1, 2)
  )
  original <- d
  result <- impute_ml(d, "y", k = 2)
  expect_identical(result$y, factor(c("b", "b", "a"), levels = levels(d$y)))
  expect_identical(d, original)
  d$y <- c(TRUE, NA, FALSE)
  expect_identical(impute_ml(d, "y", k = 2)$y, c(TRUE, TRUE, FALSE))
})

test_that("missing predictors and a single donor have defined behavior", {
  d <- data.frame(y = c(2, NA, NA), x = c(NA_real_, NA_real_, NA_real_))
  expect_equal(impute_ml(d, "y", k = 5)$y, c(2, 2, 2))
  expect_identical(impute_ml(d, "y", k = 5)$x, d$x)
  d <- data.frame(y = c(1, NA))
  expect_warning(result <- impute_ml(d, "y"), "No predictor columns")
  expect_identical(result, d)
})
