local_edition(3)

library(testthat)

make_base_data <- function() {
  set.seed(123)
  data.frame(
    SubjectID = 1:100,
    DV = rnorm(100),
    x1 = rnorm(100),
    x2 = rnorm(100)
  )
}

# When no covariates provided ---------------------------------------------

test_that("returns empty when no covariates", {
  base_data <- make_base_data()
  res <- screen_covariates_stepwise(base_data, "DV", "SubjectID", character(0))
  expect_equal(res, character(0))
})

# Signal in x1 -------------------------------------------------------------

test_that("selects covariate with signal", {
  base_data <- make_base_data()
  data_signal <- base_data
  data_signal$DV <- 2 * data_signal$x1 + rnorm(100)
  selected <- screen_covariates_stepwise(
    data_signal,
    "DV",
    "SubjectID",
    c("x1", "x2")
  )
  expect_equal(selected, "x1")
})

# NA handling --------------------------------------------------------------

test_that("handles NA values", {
  base_data <- make_base_data()
  data_signal <- base_data
  data_signal$DV <- 2 * data_signal$x1 + rnorm(100)
  data_na <- data_signal
  indices <- sample(1:100, 10)
  data_na$x1[indices] <- NA
  selected_na <- screen_covariates_stepwise(
    data_na,
    "DV",
    "SubjectID",
    c("x1", "x2")
  )
  expect_equal(selected_na, "x1")
})
