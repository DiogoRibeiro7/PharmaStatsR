local_edition(3)

library(testthat)

make_fit_data <- function() {
  set.seed(123)
  data.frame(
    SubjectID = rep(1:5, each = 2),
    Time = rep(0:1, times = 5),
    DV = rnorm(10),
    WT = rnorm(10, 70, 5),
    SEX = rep(c("M", "F"), 5)
  )
}

test_that("prepare_model_matrix returns numeric matrix", {
  fit_data <- make_fit_data()
  mat <- prepare_model_matrix(fit_data, c("Time", "WT", "SEX"))
  expect_true(is.matrix(mat))
  expect_equal(ncol(mat), 2 + length(levels(factor(fit_data$SEX))))
})

test_that("fit_covariate_model returns lme object", {
  fit_data <- make_fit_data()
  model <- fit_covariate_model(fit_data, "DV", "SubjectID", c("Time", "WT"))
  expect_s3_class(model, "lme")
})
