# Independent component-model evidence for pharma_joint_model().
# This file does NOT reimplement JM::jointModel() or validate its joint
# likelihood. The joint backend contract is tested in test-joint-model.R.

joint_component_reference_data <- function() {
  patient <- factor(rep(seq_len(6L), each = 3L))
  obstime <- rep(0:2, times = 6L)
  subject_shift <- rep(c(-1, 0, 1, -2, 2, 0), each = 3L)
  within_pattern <- rep(c(0.5, -1, 0.5), times = 6L)

  longitudinal <- data.frame(
    patient = patient,
    obstime = obstime,
    marker = 10 + subject_shift + 2 * obstime + within_pattern
  )
  survival <- data.frame(
    patient = factor(seq_len(6L)),
    Time = 3:8,
    death = c(1, 1, 0, 1, 0, 1),
    group = c(0, 1, 0, 1, 0, 1)
  )
  list(longitudinal = longitudinal, survival = survival)
}

test_that("balanced random-intercept component has independent fixed effects", {
  data <- joint_component_reference_data()$longitudinal
  X <- stats::model.matrix(~ obstime, data)
  target <- c("(Intercept)" = 10, obstime = 2)
  residual <- data$marker - drop(X %*% target)
  expect_equal(unname(drop(crossprod(X, residual))), c(0, 0), tolerance = 1e-12)

  fit <- nlme::lme(
    marker ~ obstime,
    random = ~ 1 | patient,
    data = data,
    method = "REML"
  )
  expect_equal(nlme::fixed.effects(fit), target, tolerance = 1e-8)
})

test_that("Cox component matches an independent risk-set score root", {
  data <- joint_component_reference_data()$survival
  fit <- survival::coxph(
    survival::Surv(Time, death) ~ group,
    data = data,
    ties = "breslow",
    x = TRUE,
    y = TRUE
  )

  risk_groups <- list(
    c(0, 1, 0, 1, 0, 1),
    c(1, 0, 1, 0, 1),
    c(1, 0, 1),
    1
  )
  event_group <- c(0, 1, 1, 1)
  score <- function(beta) {
    sum(vapply(seq_along(risk_groups), function(i) {
      x <- risk_groups[[i]]
      w <- exp(beta * x)
      event_group[i] - sum(x * w) / sum(w)
    }, numeric(1)))
  }

  target_beta <- 0.3401437586869536
  r <- exp(target_beta)
  expect_equal(6 * r^3 - 9 * r - 4, 0, tolerance = 1e-12)
  expect_equal(score(target_beta), 0, tolerance = 1e-12)
  expect_equal(unname(stats::coef(fit)), target_beta, tolerance = 1e-9)
  expect_equal(unname(drop(fit$x[, "group"])), data$group, tolerance = 0)
  expect_equal(sum(data$death), 4, tolerance = 0)
})

test_that("component fixtures have aligned subjects and compatible time scales", {
  fixture <- joint_component_reference_data()
  long_ids <- as.character(unique(fixture$longitudinal$patient))
  surv_ids <- as.character(fixture$survival$patient)
  expect_identical(long_ids, surv_ids)
  max_long_time <- as.numeric(tapply(
    fixture$longitudinal$obstime,
    fixture$longitudinal$patient,
    max
  ))
  expect_true(all(fixture$survival$Time >= max_long_time))
})
