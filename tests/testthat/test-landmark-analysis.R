landmark_fixture <- function() {
  data.frame(
    time = c(1, 2, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14),
    status = c(0, 1, 0, 1, 1, 0, 1, 1, 0, 1, 0, 1, 1),
    arm = factor(rep(c("control", "active"), length.out = 13)),
    score = c(NA, NA, NA, NA, 1, 3, 2, 4, 2, 1, 3, 4, 2),
    row_id = seq_len(13)
  )
}

test_that("landmark fit matches a direct Cox model on its risk set", {
  d <- landmark_fixture()
  d$.pharma_landmark_response <- d$arm
  d$score[12] <- NA_real_  # Subset removes this otherwise eligible subject.
  selected <- d[d$row_id != 12L & d$time > 5, , drop = FALSE]
  selected$time <- selected$time - 5
  direct <- survival::coxph(
    survival::Surv(time, status) ~ .pharma_landmark_response + score,
    data = selected
  )
  actual <- pharma_landmark_analysis(
    survival::Surv(time, status) ~ .pharma_landmark_response + score,
    data = d, landmark = 5, subset = row_id != 12L
  )

  expect_equal(stats::coef(actual), stats::coef(direct))
  expect_equal(actual$loglik, direct$loglik)
  expect_identical(actual$n, nrow(selected))
  expect_identical(actual$nevent, sum(selected$status))
  expect_equal(as.numeric(actual$y[, 1L]), selected$time)
})

test_that("landmark selection rejects invalid rows and response types", {
  d <- landmark_fixture()
  formula <- survival::Surv(time, status) ~ arm + score
  expect_error(pharma_landmark_analysis(formula, d, landmark = 5,
                                        subset = rep(TRUE, 2)), "subset")
  expect_error(pharma_landmark_analysis(formula, d, landmark = 5,
                                        subset = row_id < 0), "no observations")
  expect_error(pharma_landmark_analysis(formula, d, landmark = 14),
               "no observations")
  expect_error(pharma_landmark_analysis(formula, d, landmark = 5,
                                        subset = c(NA, rep(TRUE, 12))), "subset")
  d$score[6] <- NA_real_
  expect_error(pharma_landmark_analysis(formula, d, landmark = 5),
               "missing values")
  d <- landmark_fixture()
  d$time[1] <- NA_real_
  expect_error(pharma_landmark_analysis(formula, d, landmark = 5),
               "missing values")
  d <- landmark_fixture()
  d$start <- 0
  expect_error(pharma_landmark_analysis(
    survival::Surv(start, time, status) ~ arm, d, 5),
               "right-censored")
})
