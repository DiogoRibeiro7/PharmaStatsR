test_that("pharma_t_test returns htest", {
  res <- pharma_t_test(rnorm(10), rnorm(10))
  expect_s3_class(res, "htest")
})

test_that("pharma_chisq_test returns htest", {
  tbl <- matrix(c(10,5,6,9), nrow = 2)
  res <- pharma_chisq_test(tbl)
  expect_s3_class(res, "htest")
})

test_that("pharma_anova returns aov", {
  res <- pharma_anova(response ~ treatment, data = pharma_sample)
  expect_s3_class(res, "aov")
})

test_that("pharma_logistic_regression returns glm", {
  res <- pharma_logistic_regression(outcome ~ dose, data = pharma_sample)
  expect_s3_class(res, "glm")
  expect_equal(family(res)$family, "binomial")
})

test_that("pharma_sample is a data.frame", {
  expect_true(is.data.frame(pharma_sample))
  expect_equal(nrow(pharma_sample), 20)
})

test_that("pharma_crossover is a data.frame", {
  expect_true(is.data.frame(pharma_crossover))
  expect_equal(nrow(pharma_crossover), 20)
})

test_that("pharma_survival_fit returns coxph", {
  res <- pharma_survival_fit(survival::Surv(time, status) ~ treatment, data = pharma_survival)
  expect_s3_class(res, "coxph")
})

test_that("pharma_repeated_anova returns aov or aovlist", {
  res <- pharma_repeated_anova(response ~ condition + Error(subject), data = pharma_repeated)
  expect_true(inherits(res, "aov") || inherits(res, "aovlist"))
})

test_that("pharma_survival is a data.frame", {
  expect_true(is.data.frame(pharma_survival))
  expect_equal(nrow(pharma_survival), 30)
})

test_that("pharma_repeated is a data.frame", {
  expect_true(is.data.frame(pharma_repeated))
  expect_equal(nrow(pharma_repeated), 20)
})

test_that("check_ich_columns validates datasets", {
  expect_true(check_ich_columns(pharma_sample))
  bad <- pharma_sample
  names(bad)[1] <- "id"
  expect_error(check_ich_columns(bad), "Missing required columns")
})

test_that("pharma_kaplan_meier returns survfit and survdiff", {
  res <- pharma_kaplan_meier(survival::Surv(time, status) ~ treatment, data = pharma_survival)
  expect_s3_class(res$fit, "survfit")
  expect_s3_class(res$test, "survdiff")
})

test_that("pharma_parametric_survival returns survreg", {
  res <- pharma_parametric_survival(
    survival::Surv(time, status) ~ treatment,
    data = pharma_survival,
    dist = "weibull"
  )
  expect_s3_class(res, "survreg")
  expect_equal(res$dist, "weibull")
})

test_that("pharma_lmm returns lmerMod", {
  res <- pharma_lmm(response ~ condition + (1|subject), data = pharma_repeated)
  expect_s4_class(res, "lmerMod")
})

test_that("pharma_gee returns geeglm", {
  res <- pharma_gee(response ~ condition, id = subject, data = pharma_repeated)
  expect_s3_class(res, "geeglm")
})

test_that("pharma_cox_timevarying returns coxph", {
  dat <- data.frame(start = c(0, 5, 0, 7),
                    stop = c(5, 10, 7, 12),
                    status = c(0, 1, 0, 1),
                    treatment = c(0, 0, 1, 1))
  res <- pharma_cox_timevarying(Surv(start, stop, status) ~ treatment, data = dat)
  expect_s3_class(res, "coxph")
})

test_that("pharma_competing_risks returns crr", {
  dat <- pharma_survival
  res <- pharma_competing_risks(Surv(time, status) ~ treatment, data = dat)
  expect_s3_class(res, "crr")
})

test_that("pharma_landmark_analysis returns coxph", {
  res <- pharma_landmark_analysis(
    Surv(time, status) ~ treatment,
    data = pharma_survival,
    landmark = 5
  )
  expect_s3_class(res, "coxph")
})
