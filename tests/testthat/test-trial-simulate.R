test_that("trial simulation respects enrollment and observation windows", {
  set.seed(12)
  sim <- pharma_trial_simulate(
    300, arms = c("placebo", "active"), accrual_period = 2,
    follow_up = 4, dropout_rate = 0.25,
    hazard_control = 1, hazard_treatment = 0.5,
    event_dist = "weibull", event_shape = 1.5
  )
  expect_identical(sim$id, seq_len(300))
  expect_true(all(sim$treatment %in% c("placebo", "active")))
  expect_true(all(sim$enroll_time >= 0 & sim$enroll_time <= 2))
  expect_true(all(sim$time >= 0 & sim$enroll_time + sim$time <= 4 + 1e-12))
  expect_true(all(sim$status %in% 0:1 & sim$dropout %in% 0:1))
  expect_true(all(sim$status + sim$dropout <= 1))
  expect_true(any(sim$status == 1))
  expect_true(any(sim$dropout == 1))
})

test_that("zero event and dropout rates produce administrative censoring", {
  for (distribution in c("exponential", "weibull")) {
    sim <- pharma_trial_simulate(
      1, arms = c("placebo", "active"), accrual_period = 0,
      follow_up = 3, hazard_control = 0, hazard_treatment = 0,
      dropout_rate = 0, event_dist = distribution, event_shape = 2
    )
    expect_identical(sim$enroll_time, 0)
    expect_identical(sim$time, 3)
    expect_identical(sim$status, 0L)
    expect_identical(sim$dropout, 0L)
  }
})

test_that("a zero event parameter affects only its own arm", {
  set.seed(9)
  sim <- pharma_trial_simulate(
    100, accrual_period = 0, follow_up = 2, dropout_rate = 0,
    hazard_control = 0, hazard_treatment = 10
  )
  expect_true(all(sim$status[sim$treatment == "control"] == 0L))
  expect_true(any(sim$status[sim$treatment == "treatment"] == 1L))
})

test_that("Weibull event survival follows its cumulative hazard", {
  set.seed(13)
  sim <- pharma_trial_simulate(
    6000, accrual_period = 0, follow_up = 2, dropout_rate = 0,
    event_dist = "weibull", event_shape = 2,
    hazard_control = 0.2, hazard_treatment = 0.4
  )
  for (arm in c("control", "treatment")) {
    lambda <- if (arm == "control") 0.2 else 0.4
    observed <- mean(sim$status[sim$treatment == arm] == 0)
    expect_equal(observed, exp(-lambda * 2^2), tolerance = 0.04)
  }
})

test_that("exponential event and dropout outcomes follow competing-time rates", {
  lambda <- 0.4
  mu <- 0.3
  end <- 2
  set.seed(94)
  sim <- pharma_trial_simulate(
    8000, accrual_period = 0, follow_up = end,
    hazard_control = lambda, hazard_treatment = lambda,
    dropout_rate = mu
  )
  set.seed(94)
  expect_identical(sim, pharma_trial_simulate(
    8000, accrual_period = 0, follow_up = end,
    hazard_control = lambda, hazard_treatment = lambda,
    dropout_rate = mu
  ))

  # The first of two independent exponential times occurs before study end.
  failure_probability <- 1 - exp(-(lambda + mu) * end)
  expect_equal(mean(sim$status), lambda / (lambda + mu) * failure_probability,
               tolerance = 0.02)
  expect_equal(mean(sim$dropout), mu / (lambda + mu) * failure_probability,
               tolerance = 0.02)
  expect_equal(mean(sim$status + sim$dropout == 0L),
               exp(-(lambda + mu) * end), tolerance = 0.02)
  expect_true(all(sim$time[sim$status + sim$dropout == 0L] == end))
})

test_that("trial simulation rejects invalid design parameters", {
  for (n in list(0, -1, 1.5, NA_real_, Inf, "3", c(1, 2))) {
    expect_error(pharma_trial_simulate(n), "`n`")
  }
  for (arms in list("only one", c("A", "A"), c("", "B"),
                    c("A", NA_character_), c("A", "B", "C"))) {
    expect_error(pharma_trial_simulate(2, arms = arms), "`arms`")
  }
  expect_error(pharma_trial_simulate(2, accrual_period = -1), "`accrual_period`")
  expect_error(pharma_trial_simulate(2, accrual_period = NA_real_), "`accrual_period`")
  expect_error(pharma_trial_simulate(2, enroll_shape = 0), "`enroll_shape`")
  expect_error(pharma_trial_simulate(2, dropout_rate = -0.1), "`dropout_rate`")
  expect_error(pharma_trial_simulate(2, hazard_control = -1), "`hazard_control`")
  expect_error(pharma_trial_simulate(2, hazard_treatment = Inf), "`hazard_treatment`")
  expect_error(pharma_trial_simulate(2, event_shape = 0), "`event_shape`")
  expect_error(pharma_trial_simulate(2, follow_up = NA_real_), "`follow_up`")
  expect_error(pharma_trial_simulate(2, follow_up = 12), "`follow_up`")
  expect_error(pharma_trial_simulate(2, event_dist = "normal"), "arg")
})
