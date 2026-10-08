mh_rr_reference_array <- function() {
  x <- array(0, dim = c(2, 2, 3))
  x[, , 1] <- matrix(c(8, 2, 2, 8), 2, byrow = TRUE)
  x[, , 2] <- matrix(c(6, 4, 3, 7), 2, byrow = TRUE)
  x[, , 3] <- matrix(c(9, 1, 4, 6), 2, byrow = TRUE)
  x
}

test_that("MH risk ratio matches independent Greenland-Robins arithmetic", {
  x <- mh_rr_reference_array()

  r_comp <- c(4, 3, 4.5)
  s_comp <- c(1, 1.5, 2)
  t_comp <- c(1.7, 1.35, 1.45)

  expected_rr <- 23 / 9
  expected_var <- 2 / 23
  expected_se <- sqrt(expected_var)
  expected_z <- log(expected_rr) / expected_se
  expected_ci <- exp(
    log(expected_rr) +
      c(-1, 1) * stats::qnorm(0.975) * expected_se
  )

  actual <- pharma_mh_risk_ratio(x)

  expect_equal(actual$r.components, r_comp, tolerance = 1e-15)
  expect_equal(actual$s.components, s_comp, tolerance = 1e-15)
  expect_equal(actual$t.components, t_comp, tolerance = 1e-15)
  expect_equal(unname(actual$estimate), expected_rr, tolerance = 1e-15)
  expect_equal(actual$log.variance, expected_var, tolerance = 1e-15)
  expect_equal(actual$log.standard.error, expected_se, tolerance = 1e-15)
  expect_equal(unname(actual$statistic), expected_z, tolerance = 1e-15)
  expect_equal(as.numeric(actual$conf.int), expected_ci, tolerance = 1e-15)
  expect_equal(
    actual$p.value,
    2 * stats::pnorm(-abs(expected_z)),
    tolerance = 1e-15
  )
})

test_that("MH risk ratio is invariant to stratum order", {
  x <- mh_rr_reference_array()
  p <- c(3, 1, 2)

  base <- pharma_mh_risk_ratio(x)
  reordered <- pharma_mh_risk_ratio(x[, , p, drop = FALSE])

  expect_equal(reordered$estimate, base$estimate, tolerance = 1e-15)
  expect_equal(reordered$statistic, base$statistic, tolerance = 1e-15)
  expect_equal(reordered$p.value, base$p.value, tolerance = 1e-15)
  expect_equal(reordered$r.components, base$r.components[p], tolerance = 1e-15)
})

test_that("row swap returns reciprocal MH risk ratio", {
  x <- mh_rr_reference_array()
  base <- pharma_mh_risk_ratio(x)
  swapped <- pharma_mh_risk_ratio(x[2:1, , , drop = FALSE])

  expect_equal(
    unname(swapped$estimate),
    1 / unname(base$estimate),
    tolerance = 1e-15
  )
  expect_equal(
    as.numeric(swapped$conf.int),
    rev(1 / as.numeric(base$conf.int)),
    tolerance = 1e-12
  )
  expect_equal(
    unname(swapped$statistic),
    -unname(base$statistic),
    tolerance = 1e-12
  )
  expect_equal(swapped$p.value, base$p.value, tolerance = 1e-15)
})

test_that("confidence level changes only the interval", {
  x <- mh_rr_reference_array()
  base <- pharma_mh_risk_ratio(x)
  ci90 <- pharma_mh_risk_ratio(x, conf.level = 0.90)

  expect_equal(ci90$estimate, base$estimate, tolerance = 0)
  expect_equal(ci90$statistic, base$statistic, tolerance = 0)
  expect_equal(ci90$p.value, base$p.value, tolerance = 0)
  expect_equal(attr(ci90$conf.int, "conf.level"), 0.90, tolerance = 0)
  expect_gt(ci90$conf.int[[1L]], base$conf.int[[1L]])
  expect_lt(ci90$conf.int[[2L]], base$conf.int[[2L]])
})

test_that("MH risk ratio rejects malformed and undefined inputs", {
  x <- mh_rr_reference_array()

  expect_error(pharma_mh_risk_ratio(matrix(1:4, 2, 2)), "2-by-2-by-K")
  expect_error(
    pharma_mh_risk_ratio(array(1, dim = c(2, 3, 2))),
    "2-by-2-by-K"
  )

  bad <- x
  bad[1, 1, 1] <- -1
  expect_error(pharma_mh_risk_ratio(bad), "nonnegative whole-number")

  bad <- x
  bad[1, 1, 1] <- 1.5
  expect_error(pharma_mh_risk_ratio(bad), "whole-number")

  bad <- x
  bad[1, , 1] <- 0
  expect_error(pharma_mh_risk_ratio(bad), "row margins")

  no_events_exposed <- x
  no_events_exposed[1, 1, ] <- 0
  expect_error(pharma_mh_risk_ratio(no_events_exposed), "undefined")

  no_events_control <- x
  no_events_control[2, 1, ] <- 0
  expect_error(pharma_mh_risk_ratio(no_events_control), "undefined")

  expect_error(pharma_mh_risk_ratio(x, conf.level = 1), "conf.level")
})
