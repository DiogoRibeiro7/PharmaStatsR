test_that("wild bootstrap handles transformed predictors and formula offsets", {
  d <- data.frame(
    y = c(3, 4, 5, 9, 10, 14, 16, 18),
    dose = 1:8,
    known = c(0, 0.2, 0.5, 0.1, 1, 1.4, 1.5, 1.2)
  )
  formula <- y ~ log(dose) + offset(known)
  fit <- stats::lm(formula, data = d)
  set.seed(11)
  signs <- sample(c(-1, 1), nrow(d), replace = TRUE)
  expected <- stats::lm.fit(
    stats::model.matrix(fit),
    stats::fitted(fit) + stats::residuals(fit) * signs,
    offset = fit$offset
  )$coefficients

  set.seed(11)
  draws <- pharma_wild_bootstrap(formula, d, R = 1)
  expect_identical(dim(draws), c(1L, length(stats::coef(fit))))
  expect_identical(colnames(draws), names(stats::coef(fit)))
  expect_equal(unname(draws[1, ]), unname(expected))
})

test_that("wild bootstrap keeps all model rows or fails on missing data", {
  d <- data.frame(y = c(1, 2, 4, 8), x = c(2, NA, 5, 6))
  expect_error(pharma_wild_bootstrap(y ~ x, d, R = 2), "missing values")

  d$x[2] <- 3
  d$unused <- c(NA, 1, 2, 3)
  set.seed(12)
  draws <- pharma_wild_bootstrap(y ~ x, d, R = 3)
  expect_identical(dim(draws), c(3L, 2L))
  expect_true(all(is.finite(draws)))
})

test_that("wild bootstrap validates replicates and identifiable models", {
  d <- data.frame(y = c(1, 2, 4, 8), x = c(1, 2, 3, 4))
  for (bad in list(0, -1, 1.5, NA_real_, Inf, "3", c(1, 2))) {
    expect_error(pharma_wild_bootstrap(y ~ x, d, R = bad), "`R`")
  }
  expect_error(pharma_wild_bootstrap(~ x, d, R = 1), "`formula`")
  expect_error(pharma_wild_bootstrap(y ~ x + I(2 * x), d, R = 1),
               "singular")
  expect_error(pharma_wild_bootstrap(y ~ x, d[1:2, ], R = 1),
               "positive residual degrees of freedom")
  expect_error(
    pharma_wild_bootstrap(cbind(y, x) ~ 1, d, R = 1),
    "one finite numeric response vector"
  )
})
