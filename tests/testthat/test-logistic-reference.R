# The 24 Bernoulli observations below form a prespecified 2-by-2 table:
#                 event = 1  event = 0
# control                 4          8
# active                  9          3
# Thus the event odds are 4/8 and 9/3, the active/control odds ratio
# is 6, and the independent logit targets are log(1/2) and log(6).

test_that("logistic fit reproduces table-derived odds and uncertainty", {
  data <- data.frame(
    treatment = factor(rep(c("control", "active"), each = 12),
      levels = c("control", "active")
    ),
    event = c(rep(1L, 4), rep(0L, 8), rep(1L, 9), rep(0L, 3))
  )
  target <- c("(Intercept)" = log(4 / 8),
              treatmentactive = log((9 / 3) / (4 / 8)))
  fit <- pharma_logistic_regression(event ~ treatment, data = data)

  expect_named(stats::coef(fit), names(target))
  expect_equal(unname(stats::coef(fit)), unname(target),
    tolerance = 1e-6
  )
  expect_equal(exp(unname(stats::coef(fit)[2])), 6,
    tolerance = 1e-6
  )
  expect_equal(
    unname(stats::predict(fit, newdata = data.frame(
      treatment = factor(c("control", "active"),
        levels = levels(data$treatment)
      )
    ), type = "response")),
    c(4 / 12, 9 / 12), tolerance = 1e-6
  )
  # For two independent binomial groups the information gives
  # Var(log odds A) = 1/a + 1/b and
  # Var(log OR) = 1/a + 1/b + 1/c + 1/d.
  target_se <- c(
    sqrt(1 / 4 + 1 / 8),
    sqrt(1 / 4 + 1 / 8 + 1 / 9 + 1 / 3)
  )
  expect_equal(
    unname(coef(summary(fit))[, "Std. Error"]),
    target_se, tolerance = 1e-6
  )
  expect_equal(stats::nobs(fit), 24L)

  # A two-level factor models its second level as the event.
  data$event_factor <- factor(ifelse(data$event == 1L,
    "event", "nonevent"
  ), levels = c("nonevent", "event"))
  factor_fit <- pharma_logistic_regression(
    event_factor ~ treatment, data = data
  )
  expect_equal(unname(stats::coef(factor_fit)), unname(target),
    tolerance = 1e-6
  )

  # Reversing the coded event or the reference treatment changes the sign.
  data$opposite_event <- 1L - data$event
  opposite_fit <- pharma_logistic_regression(
    opposite_event ~ treatment, data = data
  )
  expect_equal(unname(stats::coef(opposite_fit)), -unname(target),
    tolerance = 1e-6
  )
  data$reference_active <- stats::relevel(data$treatment, ref = "active")
  switched_fit <- pharma_logistic_regression(
    event ~ reference_active, data = data
  )
  expect_equal(unname(stats::coef(switched_fit)),
    c(log(9 / 3), -log(6)), tolerance = 1e-6
  )
})

test_that("logistic analysis rows follow the specified missing-row policy", {
  data <- data.frame(
    treatment = factor(rep(c("control", "active"), each = 12),
      levels = c("control", "active")
    ),
    event = c(rep(1L, 4), rep(0L, 8), rep(1L, 9), rep(0L, 3)),
    unrelated = rep(NA_real_, 24)
  )
  data$event[2] <- NA_integer_
  data$treatment[14] <- NA

  fit <- pharma_logistic_regression(event ~ treatment,
    data = data, na.action = stats::na.omit
  )
  expect_equal(stats::nobs(fit), 22L)
  expect_identical(as.integer(fit$na.action), c(2L, 14L))
  expect_identical(rownames(stats::model.frame(fit)),
    as.character(setdiff(seq_len(24), c(2, 14)))
  )
  expect_error(
    pharma_logistic_regression(event ~ treatment,
      data = data, na.action = stats::na.fail
    ),
    "missing values"
  )
})
