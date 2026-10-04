# A one-parameter binomial model makes the posterior independently
# calculable. For 8 events in 12 Bernoulli trials and alpha ~ N(0, 1),
# the unnormalized density is phi(alpha) *
# plogis(alpha)^8 * (1 - plogis(alpha))^4. Quadrature gives an
# intercept mean near 0.53191 and event probability near 0.62234.

test_that("Bayesian GLM, summary, and predictive plot match a reference", {
  skip_if_not_installed("rstanarm")
  skip_if_not_installed("bayesplot")

  data <- data.frame(event = c(rep(1L, 8), rep(0L, 4)))
  weight <- function(alpha) {
    probability <- stats::plogis(alpha)
    stats::dnorm(alpha) * probability^8 * (1 - probability)^4
  }
  normalizer <- stats::integrate(weight, -12, 12)$value
  target_mean <- stats::integrate(
    function(alpha) alpha * weight(alpha), -12, 12
  )$value / normalizer
  target_probability <- stats::integrate(
    function(alpha) stats::plogis(alpha) * weight(alpha), -12, 12
  )$value / normalizer
  posterior_cdf <- function(bound) {
    stats::integrate(weight, -12, bound)$value / normalizer
  }
  target_quantiles <- vapply(c(0.1, 0.9), function(probability) {
    stats::uniroot(function(bound) {
      posterior_cdf(bound) - probability
    }, interval = c(-6, 6))$root
  }, numeric(1))
  expect_equal(target_mean, 0.53191, tolerance = 1e-4)
  expect_equal(target_probability, 0.62234, tolerance = 1e-4)

  fit <- pharma_bayesian_glm(event ~ 1, data = data,
    family = stats::binomial(),
    prior_intercept = rstanarm::normal(0, 1, autoscale = FALSE),
    algorithm = "sampling", chains = 2, iter = 1000,
    cores = 1, seed = 47, refresh = 0
  )
  expect_s3_class(fit, "stanreg")
  expect_equal(fit$family$family, "binomial")
  expect_equal(fit$family$link, "logit")

  interval <- pharma_posterior_summary(fit, prob = 0.8)
  expect_s3_class(interval, "summary.stanreg")
  expect_true(all(c("mean", "10%", "90%", "n_eff", "Rhat") %in%
    colnames(interval)))
  intercept <- interval["(Intercept)", ]
  expect_true(all(is.finite(intercept[c("mean", "10%", "90%",
    "n_eff", "Rhat")])))
  expect_lt(intercept["Rhat"], 1.1)
  expect_gt(intercept["n_eff"], 100)
  # Tolerances allow ordinary Monte Carlo variation over 1,000 retained
  # draws while distinguishing the stated posterior from the likelihood
  # estimate log(8/4) and the raw event fraction 8/12.
  expect_lt(abs(intercept["mean"] - target_mean), 0.15)
  expect_lt(max(abs(intercept[c("10%", "90%")] -
    target_quantiles)), 0.3)

  draws <- as.matrix(fit)[, "(Intercept)"]
  expect_equal(unname(intercept[c("10%", "90%")]),
    unname(stats::quantile(draws, c(0.1, 0.9))),
    tolerance = 0.02
  )
  default_interval <- pharma_posterior_summary(fit)
  expect_true(all(c("2.5%", "97.5%") %in% colnames(default_interval)))

  plot <- pharma_pp_check(fit,
    plotfun = "stat", stat = "mean", seed = 47
  )
  expect_s3_class(plot, "ggplot")
  # bayesplot::ppc_stat stores the replicated sample means in plot$data
  # and the observed statistic in the vertical-line layer.
  expect_equal(nrow(plot$data), length(draws))
  expect_false(any(plot$data$variable == "y"))
  expect_true(all(abs(12 * plot$data$value -
    round(12 * plot$data$value)) < 1e-8))
  observed_layers <- Filter(function(layer) {
    is.data.frame(layer$data) &&
      "variable" %in% names(layer$data) &&
      any(layer$data$variable == "y")
  }, plot$layers)
  expect_length(observed_layers, 1)
  expect_equal(unique(observed_layers[[1]]$data$value), 8 / 12)
  expect_lt(abs(mean(plot$data$value) - target_probability), 0.15)

  # The backend must reject an invalid Bernoulli outcome, an impossible
  # interval width, and an unknown predictive plot request.
  expect_error(pharma_bayesian_glm(event ~ 1,
    data = data.frame(event = c(0L, 2L)),
    family = stats::binomial()
  ))
  expect_error(pharma_posterior_summary(fit, prob = 1.1))
  expect_error(pharma_pp_check(fit, plotfun = "unknown_ppc"))

  cat(sprintf(
    "Bayesian reference: rstanarm %s, bayesplot %s; mean %.3f, Rhat %.3f, ESS %.0f\n",
    as.character(utils::packageVersion("rstanarm")),
    as.character(utils::packageVersion("bayesplot")),
    intercept["mean"], intercept["Rhat"], intercept["n_eff"]
  ))
})
