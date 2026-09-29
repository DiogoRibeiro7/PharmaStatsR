test_that("numeric predictors cannot silently become one-way groups", {
  dat <- data.frame(
    response = c(2, 3, 1, 6, 7, 5, 2, 3, 1),
    dose = rep(0:2, each = 3)
  )
  expect_error(pharma_anova(response ~ dose, data = dat), "categorical")

  actual <- pharma_anova(response ~ factor(dose), data = dat)
  reference <- stats::aov(response ~ factor(dose), data = dat)
  expect_s3_class(actual, "aov")
  expect_equal(stats::coef(actual), stats::coef(reference))
  expect_equal(stats::df.residual(actual), stats::df.residual(reference))
  expect_equal(summary(actual)[[1L]][["F value"]][1L],
               summary(reference)[[1L]][["F value"]][1L])
})

test_that("one-way ANOVA requires one observed categorical factor and intercept", {
  dat <- data.frame(
    response = c(2, 3, 1, 6, 7, 5, 2, 3, 1),
    group = factor(rep(c("A", "B", "C"), each = 3),
                   levels = c("A", "B", "C", "unused")),
    block = factor(rep(1:3, times = 3))
  )
  expect_equal(
    stats::coef(pharma_anova(response ~ group, data = dat)),
    stats::coef(stats::aov(response ~ group, data = dat))
  )
  expect_error(pharma_anova(response ~ group - 1, data = dat),
               "with an intercept")
  expect_error(pharma_anova(response ~ group:block, data = dat),
               "one categorical group")
  dat$group <- factor(rep("A", nrow(dat)), levels = c("A", "B"))
  expect_error(pharma_anova(response ~ group, data = dat),
               "two observed levels")
})
