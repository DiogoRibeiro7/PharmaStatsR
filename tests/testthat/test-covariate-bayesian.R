local_edition(3)

library(testthat)

make_bayes_data <- function() {
  set.seed(123)
  data.frame(
    SubjectID = 1:120,
    DV = rnorm(120),
    x1 = rnorm(120),
    x2 = rnorm(120)
  )
}

test_that("returns empty when no covariates", {
  d <- make_bayes_data()
  res <- screen_covariates_bayesian(d, "DV", character(0))
  expect_equal(res, character(0))
})

test_that("selects covariate with signal", {
  d <- make_bayes_data()
  d$DV <- 2 * d$x1 + rnorm(120, sd = 0.7)
  selected <- screen_covariates_bayesian(d, "DV", c("x1", "x2"), min_bf = 3)
  expect_true("x1" %in% selected)
})

test_that("handles NA values", {
  d <- make_bayes_data()
  d$DV <- 2 * d$x1 + rnorm(120, sd = 0.7)
  d$x1[sample(1:120, 12)] <- NA
  selected <- screen_covariates_bayesian(d, "DV", c("x1", "x2"), min_bf = 3)
  expect_true("x1" %in% selected)
})

test_that("validates min_bf input", {
  d <- make_bayes_data()
  expect_error(
    screen_covariates_bayesian(d, "DV", c("x1", "x2"), min_bf = 0),
    "`min_bf` must be a positive number"
  )
})

test_that("strong evidence remains selected beyond floating-point BF range", {
  set.seed(42)
  d <- data.frame(x = rnorm(1000))
  d$DV <- 10 * d$x + rnorm(1000, sd = 0.1)
  expect_identical(
    screen_covariates_bayesian(d, "DV", "x"),
    "x"
  )
})

test_that("non-finite thresholds are rejected", {
  d <- make_bayes_data()
  for (threshold in c(Inf, -Inf, NA_real_, NaN)) {
    expect_error(
      screen_covariates_bayesian(d, "DV", "x1", min_bf = threshold),
      "must be a positive number and finite",
      fixed = TRUE
    )
  }
})

test_that("thresholds must be real numeric scalars even without candidates", {
  d <- make_bayes_data()
  for (threshold in list(1 + 1i, "3", TRUE, numeric(0), c(1, 3), matrix(3))) {
    expect_error(
      screen_covariates_bayesian(d, "DV", "x1", min_bf = threshold),
      "must be a positive number and finite",
      fixed = TRUE
    )
  }
  expect_error(
    screen_covariates_bayesian(d, "DV", character(0), min_bf = Inf),
    "must be a positive number and finite",
    fixed = TRUE
  )
})

test_that("constant candidates cannot be selected at permissive thresholds", {
  d <- make_bayes_data()
  d$x1 <- 1
  expect_error(
    screen_covariates_bayesian(d, "DV", "x1", min_bf = 1),
    "constant on complete-case rows"
  )
})
