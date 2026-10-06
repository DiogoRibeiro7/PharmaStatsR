# Independent two-sample t-test arithmetic for pharma_scipy_ttest().
# Expected values are derived from sample moments and stats::pt(), not
# stats::t.test() or a second SciPy call.

scipy_t_reference <- function(x, y, equal_var) {
  nx <- length(x)
  ny <- length(y)
  mx <- mean(x)
  my <- mean(y)
  vx <- stats::var(x)
  vy <- stats::var(y)

  if (equal_var) {
    df <- nx + ny - 2
    pooled_var <- ((nx - 1) * vx + (ny - 1) * vy) / df
    se <- sqrt(pooled_var * (1 / nx + 1 / ny))
  } else {
    se2 <- vx / nx + vy / ny
    se <- sqrt(se2)
    df <- se2^2 / (
      (vx / nx)^2 / (nx - 1) +
        (vy / ny)^2 / (ny - 1)
    )
  }

  statistic <- (mx - my) / se
  p_value <- 2 * stats::pt(-abs(statistic), df = df)
  list(
    mean_x = mx, mean_y = my,
    var_x = vx, var_y = vy,
    se = se, df = df,
    statistic = statistic, p.value = p_value
  )
}

test_that("independent Student and Welch references are distinct", {
  x <- c(1, 2, 4, 7)
  y <- c(0, 3, 9, 10, 12)

  student <- scipy_t_reference(x, y, TRUE)
  welch <- scipy_t_reference(x, y, FALSE)

  expect_equal(student$mean_x, 3.5, tolerance = 0)
  expect_equal(student$mean_y, 6.8, tolerance = 0)
  expect_equal(student$var_x, 7, tolerance = 1e-12)
  expect_equal(student$var_y, 25.7, tolerance = 1e-12)

  expect_equal(student$se, sqrt(5571 / 700), tolerance = 1e-12)
  expect_equal(student$df, 7, tolerance = 0)
  expect_equal(student$statistic, -1.1697589605761274, tolerance = 1e-12)

  expect_equal(welch$se, sqrt(689) / 10, tolerance = 1e-12)
  expect_equal(welch$df, 6.225250467714582, tolerance = 1e-12)
  expect_equal(welch$statistic, -1.2571998743031079, tolerance = 1e-12)

  expect_gt(abs(student$statistic - welch$statistic), 0.08)
  expect_gt(abs(student$df - welch$df), 0.7)
})

test_that("installed SciPy matches independent Student and Welch arithmetic", {
  skip_if_not_installed("reticulate")
  skip_if_not(reticulate::py_module_available("scipy.stats"))

  x <- c(1, 2, 4, 7)
  y <- c(0, 3, 9, 10, 12)

  for (equal_var in c(TRUE, FALSE)) {
    expected <- scipy_t_reference(x, y, equal_var)
    actual <- pharma_scipy_ttest(x, y, equal_var = equal_var)

    expect_named(actual, c("statistic", "p.value"))
    expect_equal(actual$statistic, expected$statistic, tolerance = 1e-10)
    expect_equal(actual$p.value, expected$p.value, tolerance = 1e-10)
  }
})

test_that("group swapping changes only the sign of the t statistic", {
  skip_if_not_installed("reticulate")
  skip_if_not(reticulate::py_module_available("scipy.stats"))

  x <- c(1, 2, 4, 7)
  y <- c(0, 3, 9, 10, 12)

  for (equal_var in c(TRUE, FALSE)) {
    xy <- pharma_scipy_ttest(x, y, equal_var = equal_var)
    yx <- pharma_scipy_ttest(y, x, equal_var = equal_var)

    expect_equal(yx$statistic, -xy$statistic, tolerance = 1e-12)
    expect_equal(yx$p.value, xy$p.value, tolerance = 1e-12)
  }
})

test_that("affine transformations obey the independent t-test identities", {
  skip_if_not_installed("reticulate")
  skip_if_not(reticulate::py_module_available("scipy.stats"))

  x <- c(1, 2, 4, 7)
  y <- c(0, 3, 9, 10, 12)

  for (equal_var in c(TRUE, FALSE)) {
    base <- pharma_scipy_ttest(x, y, equal_var = equal_var)

    positive <- pharma_scipy_ttest(
      7 + 3 * x, 7 + 3 * y, equal_var = equal_var
    )
    expect_equal(positive, base, tolerance = 1e-12)

    negative <- pharma_scipy_ttest(
      7 - 3 * x, 7 - 3 * y, equal_var = equal_var
    )
    expect_equal(negative$statistic, -base$statistic, tolerance = 1e-12)
    expect_equal(negative$p.value, base$p.value, tolerance = 1e-12)
  }
})

test_that("one zero-variance group remains a defined Welch and Student case", {
  skip_if_not_installed("reticulate")
  skip_if_not(reticulate::py_module_available("scipy.stats"))

  x <- c(2, 2, 2, 2)
  y <- c(0, 1, 3, 6, 10)

  for (equal_var in c(TRUE, FALSE)) {
    expected <- scipy_t_reference(x, y, equal_var)
    actual <- pharma_scipy_ttest(x, y, equal_var = equal_var)

    expect_true(is.finite(expected$statistic))
    expect_true(is.finite(expected$p.value))
    expect_equal(actual$statistic, expected$statistic, tolerance = 1e-10)
    expect_equal(actual$p.value, expected$p.value, tolerance = 1e-10)
  }
})
