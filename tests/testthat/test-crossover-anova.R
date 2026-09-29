test_that("crossover example is a balanced AB/BA design", {
  dat <- pharma_crossover
  expect_true(all(vapply(dat[c("treatment", "period", "subject")],
                         is.factor, logical(1))))
  expect_true(all(table(dat$subject, dat$period) == 1L))
  expect_true(all(table(dat$subject, dat$treatment) == 1L))
  expect_true(all(table(dat$period, dat$treatment) == 5L))

  fit <- pharma_crossover_anova(
    response ~ treatment + period + subject, data = dat
  )
  reference <- stats::aov(
    response ~ treatment + period + subject, data = dat
  )
  expect_s3_class(fit, "aov")
  expect_equal(stats::coef(fit), stats::coef(reference))
  expect_false(anyNA(stats::coef(fit)))
  expect_equal(as.numeric(summary(fit)[[1L]][["Df"]]), c(1, 1, 9, 8))
})

test_that("crossover accepts explicit factors for numeric design IDs", {
  dat <- pharma_crossover
  dat$subject <- as.integer(dat$subject)
  dat$period <- as.integer(dat$period)

  expect_error(
    pharma_crossover_anova(response ~ treatment + period + subject, dat),
    "factor"
  )
  fit <- pharma_crossover_anova(
    response ~ treatment + factor(period) + factor(subject), dat
  )
  reference <- stats::aov(
    response ~ treatment + factor(period) + factor(subject), data = dat
  )
  expect_equal(stats::coef(fit), stats::coef(reference))
})

test_that("crossover rejects parallel groups and repeated visits", {
  parallel <- pharma_crossover
  parallel$treatment <- factor(rep(c("A", "B"), each = 10))
  expect_error(
    pharma_crossover_anova(
      response ~ treatment + period + subject, parallel
    ),
    "receive both treatments"
  )

  repeated <- pharma_crossover
  repeated$period[2L] <- repeated$period[1L]
  expect_error(
    pharma_crossover_anova(
      response ~ treatment + period + subject, repeated
    ),
    "one observation in each period"
  )

  incomplete <- pharma_crossover[-1L, ]
  expect_error(
    pharma_crossover_anova(
      response ~ treatment + period + subject, incomplete
    ),
    "one observation in each period"
  )
})

test_that("crossover requires balanced AB and BA sequences", {
  dat <- pharma_crossover
  dat$treatment[1:2] <- rev(dat$treatment[1:2])
  expect_error(
    pharma_crossover_anova(response ~ treatment + period + subject, dat),
    "equal numbers"
  )

  too_small <- pharma_crossover[1:4, ]
  expect_error(
    pharma_crossover_anova(
      response ~ treatment + period + subject, too_small
    ),
    "at least four"
  )
})

test_that("crossover rejects undefined or inappropriate models", {
  dat <- pharma_crossover
  expect_error(
    pharma_crossover_anova(response ~ treatment + period, dat),
    "three main effects"
  )
  expect_error(
    pharma_crossover_anova(
      response ~ treatment * period + subject, dat
    ),
    "three main effects"
  )
  expect_error(
    pharma_crossover_anova(
      response ~ treatment + period + subject - 1, dat
    ),
    "intercept"
  )

  dat$response[1L] <- NA_real_
  expect_error(
    pharma_crossover_anova(response ~ treatment + period + subject, dat),
    "NA values"
  )
  dat$response[1L] <- Inf
  expect_error(
    pharma_crossover_anova(response ~ treatment + period + subject, dat),
    "finite numeric"
  )
  expect_error(
    pharma_crossover_anova(
      response ~ treatment + period + subject, pharma_crossover,
      subset = subject != "1"
    ),
    "not supported"
  )
})
