test_that("rate intervals match independent numerical references", {
  # Wilson bounds from SciPy 1.17.0's binomtest(...).proportion_ci(method = "wilson"),
  # combined with Newcombe's difference construction. Ratio bounds use
  # a half-count in all four cells of an independent two-by-two table.
  ordinary <- pharma_rate_metrics(10, 100, 15, 110)
  expect_equal(ordinary$risk_difference, 0.1 - 15 / 110)
  expect_equal(ordinary$risk_ratio, 0.1 / (15 / 110))
  expect_equal(ordinary$rd_ci, c(-0.1249956110, 0.0543516842),
               tolerance = 1e-8)
  expect_equal(ordinary$rr_ci, c(0.3567877359, 1.5534901149),
               tolerance = 1e-8)

  ninety <- pharma_rate_metrics(3, 25, 7, 40, conf.level = 0.9)
  expect_equal(ninety$rd_ci, c(-0.1930772617, 0.1094879418),
               tolerance = 1e-8)
  expect_equal(ninety$rr_ci, c(0.2757257846, 1.9640710675),
               tolerance = 1e-8)
})

test_that("boundary event counts retain meaningful intervals", {
  none <- pharma_rate_metrics(0, 12, 0, 15)
  expect_equal(none$risk_difference, 0)
  expect_true(is.na(none$risk_ratio))
  expect_equal(none$rd_ci, c(-0.2038833010, 0.2424940067),
               tolerance = 1e-8)
  expect_equal(none$rr_ci, c(0.0261641103, 57.8958306704),
               tolerance = 1e-8)

  first_none <- pharma_rate_metrics(0, 12, 5, 15)
  expect_equal(first_none$risk_ratio, 0)
  expect_true(all(is.finite(first_none$rr_ci)))
  expect_true(first_none$rd_ci[2] < 0)

  second_none <- pharma_rate_metrics(5, 12, 0, 15)
  expect_equal(second_none$risk_ratio, Inf)
  expect_true(all(is.finite(second_none$rr_ci)))
  expect_true(second_none$rd_ci[1] > 0)

  all_events <- pharma_rate_metrics(8, 8, 12, 12)
  expect_equal(all_events$risk_ratio, 1)
  expect_equal(all_events$rd_ci, c(-0.3244075649, 0.2424940067),
               tolerance = 1e-8)
  expect_equal(all_events$rr_ci, c(0.8105008760, 1.1903262814),
               tolerance = 1e-8)
})

test_that("rate inputs are scalar, finite whole counts and a valid confidence level", {
  for (bad in list(NA_real_, Inf, -1, 1.5, c(1, 2), "1", TRUE)) {
    expect_error(pharma_rate_metrics(bad, 10, 1, 10), "event1")
    expect_error(pharma_rate_metrics(1, bad, 1, 10), "n1")
  }
  expect_error(pharma_rate_metrics(11, 10, 1, 10),
               "cannot exceed sample sizes")
  expect_error(pharma_rate_metrics(1, 10, 11, 10),
               "cannot exceed sample sizes")
  expect_error(pharma_rate_metrics(1, 0, 1, 10), "n1")
  expect_error(pharma_rate_metrics(1, 10, 1, -10), "n2")

  for (bad in list(NA_real_, Inf, -0.1, 0, 1, 1.1, c(0.9, 0.95), "0.95")) {
    expect_error(pharma_rate_metrics(1, 10, 1, 10, conf.level = bad),
                 "conf.level")
  }
})
