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
