test_that("pharma_t_test returns htest", {
  res <- pharma_t_test(rnorm(10), rnorm(10))
  expect_s3_class(res, "htest")
})

test_that("pharma_chisq_test returns htest", {
  tbl <- matrix(c(10, 5, 6, 9), nrow = 2)
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

test_that("pharma_survival is a data.frame", {
  expect_true(is.data.frame(pharma_survival))
  expect_equal(nrow(pharma_survival), 30)
})

test_that("pharma_repeated is a data.frame", {
  expect_true(is.data.frame(pharma_repeated))
  expect_equal(nrow(pharma_repeated), 20)
})

test_that("pharma_dose_response is a data.frame", {
  expect_true(is.data.frame(pharma_dose_response))
  expect_equal(nrow(pharma_dose_response), 30)
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
  skip_if_not_installed("lme4")
  res <- pharma_lmm(response ~ condition + (1 | subject), data = pharma_repeated)
  expect_s4_class(res, "lmerMod")
})

test_that("pharma_gee returns geeglm", {
  skip_if_not_installed("geepack")
  res <- pharma_gee(response ~ condition, id = pharma_repeated$subject, data = pharma_repeated)
  expect_s3_class(res, "geeglm")
})

test_that("pharma_cox_timevarying returns coxph", {
  # Eight subjects contribute a baseline and a later interval. Treatment
  # changes for some subjects, and events occur in both treatment groups.
  dat <- data.frame(
    start = rep(c(0, 5), 8),
    stop = as.vector(rbind(rep(5, 8), 6:13)),
    status = rep(c(0, 1), 8),
    treatment = as.vector(rbind(
      c(0, 0, 1, 1, 0, 0, 1, 1),
      c(0, 1, 1, 0, 1, 0, 0, 1)
    ))
  )
  expect_silent(
    res <- pharma_cox_timevarying(
      survival::Surv(start, stop, status) ~ treatment, data = dat
    )
  )
  expect_s3_class(res, "coxph")
  expect_true(all(is.finite(stats::coef(res))))
})

test_that("pharma_competing_risks returns crr", {
  skip_if_not_installed("cmprsk")
  skip_if_not_installed("survival")
  dat <- pharma_survival
  res <- pharma_competing_risks(survival::Surv(time, status) ~ treatment, data = dat)
  expect_s3_class(res, "crr")
})

test_that("pharma_landmark_analysis returns coxph", {
  skip_if_not_installed("survival")
  res <- pharma_landmark_analysis(
    survival::Surv(time, status) ~ treatment,
    data = pharma_survival,
    landmark = 5
  )
  expect_s3_class(res, "coxph")
})

test_that("pharma_bayesian_glm returns stanreg", {
  skip_if_not_installed("rstanarm")
  skip_if_not_installed("bayesplot")
  fit <- pharma_bayesian_glm(outcome ~ dose, data = pharma_sample, iter = 10, chains = 1, refresh = 0)
  expect_s3_class(fit, "stanreg")
  summ <- pharma_posterior_summary(fit)
  expect_s3_class(summ, "summary.stanreg")
  plot <- pharma_pp_check(fit, plotfun = "hist", nreps = 2, seed = 42)
  expect_s3_class(plot, "ggplot")
})

test_that("pharma_meta_analysis returns rma", {
  skip_if_not_installed("metafor")
  res <- pharma_meta_analysis(yi = c(0.2, 0.1, -0.1), vi = c(0.05, 0.04, 0.06))
  expect_s3_class(res, "rma")
})

test_that("pharma_forest_plot runs", {
  skip_if_not_installed("metafor")
  res <- pharma_meta_analysis(yi = c(0.2, 0.1, -0.1), vi = c(0.05, 0.04, 0.06))
  expect_silent(pharma_forest_plot(res))
})

test_that("pharma_funnel_plot runs", {
  skip_if_not_installed("metafor")
  res <- pharma_meta_analysis(yi = c(0.2, 0.1, -0.1), vi = c(0.05, 0.04, 0.06))
  expect_silent(pharma_funnel_plot(res))
})

test_that("pharma_network_meta_analysis returns netmeta", {
  skip_if_not_installed("netmeta")
  df <- data.frame(
    treat1 = c("A", "A", "B"),
    treat2 = c("B", "C", "C"),
    TE = c(0.2, 0.5, -0.1),
    seTE = c(0.1, 0.2, 0.1),
    study = c("s1", "s2", "s3")
  )
  res <- pharma_network_meta_analysis(TE, seTE, treat1, treat2,
                                      data = df, studlab = df$study,
                                      random = FALSE)
  expect_s3_class(res, "netmeta")
})

test_that("pharma_emax returns nls", {
  res <- pharma_emax(pharma_dose_response$dose, pharma_dose_response$response)
  expect_s3_class(res, "nls")
})

test_that("pharma_sigmoid_emax returns nls", {
  res <- pharma_sigmoid_emax(pharma_dose_response$dose, pharma_dose_response$response)
  expect_s3_class(res, "nls")
})

test_that("pharma_emax_nlme returns lme", {
  skip_if_not_installed("nlme")
  res <- pharma_emax_nlme(
    pharma_dose_response$dose,
    pharma_dose_response$response,
    subject = pharma_dose_response$subject
  )
  expect_s3_class(res, "lme")
})

test_that("pharma_group_seq returns numeric", {
  res <- pharma_group_seq(k = 3)
  expect_type(res, "double")
  expect_length(res, 3)
})

test_that("pharma_sample_reestimate returns numeric", {
  res <- pharma_sample_reestimate(50, 0.5, 1)
  expect_type(res, "double")
  expect_true(res >= 50)
})

test_that("pharma_bayes_stopping returns list", {
  out <- pharma_bayes_stopping(1, 1, 5, 10)
  expect_type(out$prob, "double")
  expect_type(out$stop, "logical")
})

test_that("pharma_crossover_anova returns aov", {
  res <- pharma_crossover_anova(response ~ treatment + period + subject, data = pharma_crossover)
  expect_s3_class(res, "aov")
})

test_that("pharma_latin_square_anova returns aov", {
  res <- pharma_latin_square_anova(response ~ treatment + row + column, data = pharma_latin_square)
  expect_s3_class(res, "aov")
})


test_that("pharma_mice_impute returns mids", {
  skip_if_not_installed("mice")
  dat <- pharma_sample
  dat$response[1] <- NA
  imp <- pharma_mice_impute(dat, m = 2, maxit = 1)
  expect_s3_class(imp, "mids")
})

test_that("pharma_trial_simulate returns data.frame", {
  sim <- pharma_trial_simulate(30)
  expect_true(is.data.frame(sim))
  expect_equal(ncol(sim), 6)
  expect_true(all(c("id", "treatment", "enroll_time", "time", "status", "dropout") %in% names(sim)))
})

test_that("pharma_trial_simulate supports Weibull events", {
  sim <- pharma_trial_simulate(30,
    event_dist = "weibull", event_shape = 1.5,
    accrual_period = 6, follow_up = 18
  )
  expect_true(max(sim$enroll_time) <= 6)
  expect_true(all(sim$time >= 0))
})

test_that("pharma_sensitivity_analysis returns pool", {
  skip_if_not_installed("mice", minimum_version = "3.15.0")
  dat <- pharma_sample
  dat$response[1] <- NA
  imp <- pharma_mice_impute(dat, m = 2, maxit = 1)
  res <- pharma_sensitivity_analysis(imp, response ~ treatment)
  expect_s3_class(res, "mipo")
})

test_that("pharma_wild_bootstrap returns matrix", {
  res <- pharma_wild_bootstrap(response ~ treatment, data = pharma_sample, R = 5)
  expect_true(is.matrix(res))
  expect_equal(nrow(res), 5)
})

test_that("pharma_block_bootstrap returns list", {
  stat <- function(d) mean(d$response)
  res <- pharma_block_bootstrap(pharma_sample, "subject", stat, R = 5)
  expect_length(res, 5)
})

test_that("pharma_tost returns expected structure", {
  x <- rnorm(20, 0)
  y <- rnorm(20, 0.1)
  res <- pharma_tost(x, y, -0.5, 0.5)
  expect_type(res$p.value, "double")
  expect_length(res$statistic, 2)
})

test_that("pharma_rate_metrics returns numeric outputs", {
  res <- pharma_rate_metrics(10, 100, 12, 110)
  expect_true(is.numeric(res$risk_difference))
  expect_length(res$rd_ci, 2)
  expect_true(is.numeric(res$risk_ratio))
})
