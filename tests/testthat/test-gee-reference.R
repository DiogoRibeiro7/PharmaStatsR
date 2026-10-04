test_that("pharma_gee matches a cluster-score sandwich reference", {
  skip_if_not_installed("geepack")

  # Four independent clusters, with two complete visits per cluster.
  # At x = 0 and 1, the sample means are 2 and 5, so beta = (2, 3).
  dat <- data.frame(
    subject = rep(1:4, each = 2),
    condition = rep(c(0, 1), times = 4),
    response = c(3, 6, 1, 5, 2, 4, 2, 5)
  )
  fit <- pharma_gee(
    response ~ condition, id = subject, data = dat,
    family = stats::gaussian(), corstr = "independence"
  )

  # X'X = [8, 4; 4, 4]. At beta = (2, 3), the four cluster scores
  # X_i'(y_i - X_i beta) are (2, 1), (-1, 0), (-1, -1), (0, 0).
  # Their outer products sum to [6, 3; 3, 2]. The uncorrected robust
  # sandwich (X'X)^-1 meat (X'X)^-1 is [1/8, -1/16; -1/16, 1/8].
  covariance <- matrix(c(1 / 8, -1 / 16, -1 / 16, 1 / 8), nrow = 2)
  expect_equal(unname(stats::coef(fit)), c(2, 3), tolerance = 1e-7)
  expect_equal(unname(stats::vcov(fit)), covariance, tolerance = 1e-7)
  expect_equal(unname(sqrt(diag(stats::vcov(fit)))),
               rep(sqrt(1 / 8), 2), tolerance = 1e-7)
  expect_equal(unname(fit$id), dat$subject)
  expect_equal(length(stats::fitted(fit)), nrow(dat))
  expect_equal(unname(stats::fitted(fit)), rep(c(2, 5), times = 4),
               tolerance = 1e-7)
})
