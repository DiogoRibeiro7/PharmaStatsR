# Balanced two-condition random-intercept reference. With eight independent
# subjects, each subject contributes a control and active observation.
# The within-subject differences are 2 + delta, where mean(delta) = 0 and
# sample Var(delta) = 0.04. Subject means are 11 + offset, with sample
# Var(offset) = 0.96. For a balanced random-intercept REML fit, the
# independent targets are residual variance 0.04/2 = 0.02 and intercept
# variance 0.96 - 0.02/2 = 0.95.

lmm_reference_data <- function() {
  subject_ids <- paste0("s", seq_len(8))
  offsets <- c(-1.4, -1, -0.6, -0.2, 0.2, 0.6, 1, 1.4)
  delta <- c(-0.3, -0.2, -0.1, 0, 0, 0.1, 0.2, 0.3)
  subject_index <- rep(seq_along(subject_ids), each = 2)
  data <- data.frame(
    subject = factor(rep(subject_ids, each = 2), levels = subject_ids),
    condition = factor(rep(c("control", "active"), times = 8),
      levels = c("control", "active")
    )
  )
  condition_sign <- ifelse(data$condition == "active", 1, -1)
  data$response <- 11 + offsets[subject_index] +
    condition_sign * (1 + delta[subject_index] / 2)
  data
}

test_that("linear mixed fit matches a balanced REML reference", {
  skip_if_not_installed("lme4")
  data <- lmm_reference_data()
  fit <- pharma_lmm(response ~ condition + (1 | subject), data = data)

  expect_s4_class(fit, "lmerMod")
  expect_named(lme4::fixef(fit), c("(Intercept)", "conditionactive"))
  expect_equal(unname(lme4::fixef(fit)), c(10, 2),
    tolerance = 1e-3
  )
  expect_equal(stats::nobs(fit), 16L)
  expect_false(lme4::isSingular(fit))
  expect_equal(stats::sigma(fit)^2, 0.02, tolerance = 0.03)
  variance <- as.data.frame(lme4::VarCorr(fit))
  expect_equal(variance$vcov[variance$grp == "subject"],
    0.95, tolerance = 0.03
  )
  # The paired difference has variance 0.04, so its mean over
  # eight subjects has standard error sqrt(0.04/8).
  expect_equal(
    summary(fit)$coefficients["conditionactive", "Std. Error"],
    sqrt(0.04 / 8), tolerance = 0.03
  )

  newdata <- data.frame(
    condition = factor(c("control", "active"),
      levels = levels(data$condition)
    ),
    subject = factor(c("s1", "s1"), levels = levels(data$subject))
  )
  expect_equal(unname(stats::predict(fit, newdata = newdata,
    re.form = NA
  )), c(10, 12), tolerance = 1e-3)
  conditional <- stats::predict(fit, newdata = newdata)
  expect_equal(unname(diff(conditional)), 2, tolerance = 1e-3)
  offsets <- c(-1.4, -1, -0.6, -0.2, 0.2, 0.6, 1, 1.4)
  expect_gt(stats::cor(
    lme4::ranef(fit)$subject[, "(Intercept)"], offsets
  ), 0.95)
})

test_that("linear mixed fit selects model rows and rejects one group", {
  skip_if_not_installed("lme4")
  data <- lmm_reference_data()
  data$unrelated <- rep(NA_real_, nrow(data))
  data$response[2] <- NA_real_
  fit <- pharma_lmm(response ~ condition + (1 | subject),
    data = data, na.action = stats::na.omit
  )
  expect_equal(stats::nobs(fit), 15L)
  expect_identical(rownames(stats::model.frame(fit)),
    as.character(setdiff(seq_len(16), 2L))
  )
  expect_error(pharma_lmm(
    response ~ condition + (1 | subject),
    data = droplevels(subset(lmm_reference_data(), subject == "s1"))
  ))
})
