# Independent targets below use paired observations at each dose. Each pair has
# residuals -0.05 and +0.05 around a prespecified curve, so the curve
# parameters minimize squared error with nonzero residual variance.

test_that("standard Emax recovers a reference curve and uncertainty", {
  dose_grid <- c(0, 1, 2, 4, 8)
  target <- c(e0 = 2, emax = 6, ed50 = 2)
  mean_curve <- c(2, 4, 5, 6, 6.8)
  dose <- rep(dose_grid, each = 2)
  response <- rep(mean_curve, each = 2) +
    rep(c(-0.05, 0.05), times = length(dose_grid))

  fit <- pharma_emax(dose, response,
    start = list(e0 = 1.8, emax = 5.5, ed50 = 1.7)
  )
  expect_named(stats::coef(fit), names(target))
  expect_equal(unname(stats::coef(fit)), unname(target), tolerance = 1e-4)
  expect_equal(
    unname(stats::predict(fit, newdata = data.frame(dose = dose_grid))),
    mean_curve, tolerance = 1e-4
  )

  # Derivatives of e0 + emax*d/(ed50+d), evaluated at the known curve.
  jacobian <- cbind(
    e0 = rep(1, length(dose)),
    emax = dose / (target["ed50"] + dose),
    ed50 = -target["emax"] * dose / (target["ed50"] + dose)^2
  )
  residual_variance <- sum(rep(c(-0.05, 0.05), 5)^2) /
    (length(dose) - length(target))
  reference_variance <- diag(solve(crossprod(jacobian))) *
    residual_variance
  expect_equal(
    unname(diag(stats::vcov(fit))),
    unname(reference_variance), tolerance = 1e-3
  )

  expect_error(pharma_emax(rep(1, 8), c(3.9, 4.1)[rep(1:2, 4)]))
})

test_that("sigmoid Emax recovers the Hill curve and uncertainty", {
  dose_grid <- c(0, 1, 2, 4, 8)
  target <- c(e0 = 1, emax = 8, ed50 = 2, h = 2)
  mean_curve <- c(1, 2.6, 5, 7.4, 1 + 8 * 64 / 68)
  dose <- rep(dose_grid, each = 2)
  response <- rep(mean_curve, each = 2) +
    rep(c(-0.05, 0.05), times = length(dose_grid))

  fit <- pharma_sigmoid_emax(dose, response,
    start = list(e0 = 0.9, emax = 7.7, ed50 = 1.9, h = 1.8)
  )
  expect_named(stats::coef(fit), names(target))
  expect_equal(unname(stats::coef(fit)), unname(target), tolerance = 1e-4)
  expect_equal(
    unname(stats::predict(fit, newdata = data.frame(dose = dose_grid))),
    mean_curve, tolerance = 1e-4
  )

  # Fractional response p = d^h/(ed50^h + d^h). Its Hill derivative is
  # p*(1-p)*log(d/ed50), with the zero-dose limit equal to zero.
  fraction <- dose^target["h"] /
    (target["ed50"]^target["h"] + dose^target["h"])
  hill_derivative <- numeric(length(dose))
  positive <- dose > 0
  hill_derivative[positive] <- target["emax"] *
    fraction[positive] * (1 - fraction[positive]) *
    log(dose[positive] / target["ed50"])
  jacobian <- cbind(
    e0 = rep(1, length(dose)),
    emax = fraction,
    ed50 = -target["emax"] * target["h"] *
      target["ed50"]^(target["h"] - 1) * dose^target["h"] /
      (target["ed50"]^target["h"] + dose^target["h"])^2,
    h = hill_derivative
  )
  residual_variance <- sum(rep(c(-0.05, 0.05), 5)^2) /
    (length(dose) - length(target))
  reference_variance <- diag(solve(crossprod(jacobian))) *
    residual_variance
  expect_equal(
    unname(diag(stats::vcov(fit))),
    unname(reference_variance), tolerance = 1e-3
  )

  expect_error(pharma_sigmoid_emax(
    rep(1, 8), c(3.9, 4.1)[rep(1:2, 4)]
  ))
})

test_that("mixed Emax identifies a shared curve and random baselines", {
  skip_if_not_installed("nlme")
  dose_grid <- c(0, 1, 2, 4, 8)
  subject_ids <- paste0("s", seq_len(8))
  offsets <- c(-0.4, -0.3, -0.2, -0.1, 0.1, 0.2, 0.3, 0.4)
  data <- expand.grid(
    dose = dose_grid,
    replicate = seq_len(2),
    subject = subject_ids
  )
  # Mean targets 2, 4, 5, 6, 6.8 are calculated from
  # e0 = 2, emax = 6, ed50 = 2, independently of the wrapper.
  population_mean <- c(2, 4, 5, 6, 6.8)[match(data$dose, dose_grid)]
  response <- population_mean +
    offsets[match(as.character(data$subject), subject_ids)] +
    ifelse(data$replicate == 1, -0.08, 0.08)

  fit <- pharma_emax_nlme(
    data$dose, response, subject = data$subject,
    start = c(e0 = 1.9, emax = 5.8, ed50 = 1.8)
  )
  expect_s3_class(fit, "lme")
  expect_equal(
    unname(nlme::fixef(fit)), c(2, 6, 2), tolerance = 0.12
  )
  expect_equal(
    unname(stats::predict(fit, level = 0))[seq_along(dose_grid)],
    c(2, 4, 5, 6, 6.8), tolerance = 0.12
  )
  estimated_offsets <- nlme::ranef(fit)[, "e0"]
  expect_equal(length(estimated_offsets), length(subject_ids))
  expect_gt(stats::cor(estimated_offsets, offsets), 0.9)

  # Without dose variation the pooled nonlinear starting fit is singular.
  expect_error(pharma_emax_nlme(
    rep(1, 8), c(3.9, 4.1)[rep(1:2, 4)],
    subject = rep(c("a", "b"), each = 4)
  ))
})
