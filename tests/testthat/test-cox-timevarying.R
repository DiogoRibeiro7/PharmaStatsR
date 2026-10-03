cox_interval_fixture <- function() {
  data.frame(
    id = rep(seq_len(8), each = 2),
    start = rep(c(0, 5), 8),
    stop = as.vector(rbind(rep(5, 8), c(6, 6, 7, 8, 9, 10, 11, 12))),
    event = rep(c(0, 1), 8),
    treatment = as.vector(rbind(
      c(0, 0, 1, 1, 0, 0, 1, 1),
      c(0, 1, 1, 0, 1, 0, 0, 1)
    ))
  )
}

test_that("time-varying Cox fit matches a direct counting-process model", {
  d <- cox_interval_fixture()
  d$treatment[d$id == 1L] <- NA_real_
  selected <- d[d$id > 1L, , drop = FALSE]
  formula <- survival::Surv(start, stop, event) ~ treatment
  reference <- survival::coxph(formula, data = selected, ties = "efron")
  actual <- pharma_cox_timevarying(
    formula, data = d, subset = id > 1L, ties = "efron"
  )

  expect_equal(stats::coef(actual), stats::coef(reference))
  expect_equal(actual$loglik, reference$loglik)
  expect_identical(actual$n, nrow(selected))
  expect_identical(actual$nevent, sum(selected$event))
  expect_equal(unname(actual$y), unname(reference$y))
})

test_that("time-varying Cox helper rejects unsupported or changing rows", {
  d <- cox_interval_fixture()
  formula <- survival::Surv(start, stop, event) ~ treatment
  expect_error(pharma_cox_timevarying(
    survival::Surv(stop, event) ~ treatment, d), "counting-process"
  )
  expect_error(pharma_cox_timevarying(formula, d, subset = seq_len(nrow(d))),
               "subset")
  expect_error(pharma_cox_timevarying(formula, d, subset = rep(TRUE, 2)),
               "subset")
  expect_error(pharma_cox_timevarying(formula, d, subset = rep(FALSE, nrow(d))),
               "no observations")

  bad <- d
  bad$stop[1] <- bad$start[1]
  expect_error(suppressWarnings(pharma_cox_timevarying(formula, bad)),
               "finite start < stop")
  bad <- d
  bad$event[1] <- NA_real_
  expect_error(pharma_cox_timevarying(formula, bad), "complete status")
  bad <- d
  bad$treatment[1] <- NA_real_
  expect_error(pharma_cox_timevarying(formula, bad),
               "model variables must be complete")
  expect_error(pharma_cox_timevarying(formula, list()), "data")
})
