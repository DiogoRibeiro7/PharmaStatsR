test_that("pharma_scipy_ttest reports missing reticulate", {
  testthat::local_mocked_bindings(
    .pharma_reticulate_available = function() FALSE
  )
  expect_error(pharma_scipy_ttest(1:3, 4:6),
               "install.packages\\('reticulate'\\)")
})

test_that("pharma_scipy_ttest reports missing Python SciPy", {
  testthat::local_mocked_bindings(
    .pharma_reticulate_available = function() TRUE,
    .pharma_scipy_available = function() FALSE
  )
  expect_error(pharma_scipy_ttest(1:3, 4:6),
               "scipy.stats.*python -m pip install scipy")
})

test_that("installed SciPy agrees with fixed and R t-test references", {
  skip_if_not_installed("reticulate")
  skip_if_not(reticulate::py_module_available("scipy.stats"))

  x <- c(1, 2, 4, 7, 8)
  y <- c(3, 5, 9, 10, 12)
  for (equal_var in c(TRUE, FALSE)) {
    result <- pharma_scipy_ttest(x, y, equal_var = equal_var)
    reference <- stats::t.test(x, y, var.equal = equal_var)
    expected_p <- if (equal_var) 0.1515678010503079 else 0.15294498940713883

    expect_type(result$statistic, "double")
    expect_type(result$p.value, "double")
    expect_equal(result$statistic, -1.5852581740085332, tolerance = 1e-10)
    expect_equal(result$p.value, expected_p, tolerance = 1e-10)
    expect_equal(result$statistic, unname(reference$statistic),
                 tolerance = 1e-10)
    expect_equal(result$p.value, reference$p.value, tolerance = 1e-10)
  }
})
