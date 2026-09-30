library(testthat)

set.seed(123)

test_that("pharma_meta_analysis obeys basic statistical properties", {
  skip_if_not_installed("metafor")
  for (i in 1:100) {
    n_studies <- sample(3:20, 1)
    yi <- rnorm(n_studies)
    vi <- runif(n_studies, 0.01, 0.2)
    fe_meta <- pharma_meta_analysis(yi, vi, method = "FE")
    weights <- 1/vi
    expect_equal(as.numeric(fe_meta$b), sum(yi * weights)/sum(weights), tolerance = 1e-10)
  }
})

test_that("requested FE and REML fits agree with the metafor backend", {
  skip_if_not_installed("metafor")
  yi <- c(-0.5, 0.1, 0.8, 1.4, 1.8)
  vi <- c(0.04, 0.05, 0.03, 0.06, 0.05)

  for (method in c("FE", "REML")) {
    fit <- pharma_meta_analysis(yi, vi, method = method)
    reference <- metafor::rma(yi = yi, vi = vi, method = method)
    expect_s3_class(fit, "rma")
    expect_identical(fit$method, method)
    expect_equal(fit$b, reference$b, tolerance = 1e-12)
    expect_equal(fit$se, reference$se, tolerance = 1e-12)
    expect_equal(fit$tau2, reference$tau2, tolerance = 1e-12)
    if (method == "FE") {
      # Inverse-variance weighted mean and its known-variance standard error.
      expect_equal(as.numeric(fit$b), 0.6565217391304348,
                   tolerance = 1e-12)
      expect_equal(as.numeric(fit$se), 0.09325048082403138,
                   tolerance = 1e-12)
    }
  }
})

test_that("a singular random-effects error cannot trigger an FE retry", {
  skip_if_not_installed("metafor")
  attempted <- character()
  testthat::local_mocked_bindings(
    .pharma_meta_rma = function(yi, vi, method, ...) {
      attempted <<- c(attempted, method)
      stop("Fisher information matrix is singular", call. = FALSE)
    }
  )

  expect_error(
    pharma_meta_analysis(c(0.2, 0.1, -0.1), c(0.05, 0.04, 0.06)),
    "Fisher information matrix is singular"
  )
  expect_identical(attempted, "REML")
})

test_that("method rejects missing and empty values", {
  skip_if_not_installed("metafor")
  yi <- c(0.2, 0.1, -0.1)
  vi <- c(0.05, 0.04, 0.06)
  expect_error(pharma_meta_analysis(yi, vi, method = NA_character_),
               "nonempty character scalar")
  expect_error(pharma_meta_analysis(yi, vi, method = ""),
               "nonempty character scalar")
})
