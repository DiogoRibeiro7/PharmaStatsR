make_perm_f_data <- function() {
  data.frame(
    x1 = rep(0:1, each = 4),
    x2 = rep(1:4, times = 2),
    y = c(1, 2, 2, 4, 2, 3, 5, 7)
  )
}

test_that("permutation statistic tests all predictors jointly", {
  dat <- make_perm_f_data()
  set.seed(42)
  result <- pharma_perm_f_test(y ~ x1 + x2, dat, R = 20)
  model <- stats::lm(y ~ x1 + x2, data = dat)

  # Independent least-squares reference: global F is 23.9423,
  # while the first sequential ANOVA row is 15.3846.
  expect_equal(result$statistic, 23.9423076923, tolerance = 1e-8)
  expect_equal(result$statistic,
               unname(summary(model)$fstatistic[["value"]]),
               tolerance = 1e-8)
  first_term <- stats::anova(model)[["F value"]][1]
  expect_equal(first_term, 15.3846153846, tolerance = 1e-8)
  expect_gt(abs(result$statistic - first_term), 5)

  set.seed(42)
  reference <- replicate(20, {
    shuffled <- sample(dat$y)
    unname(summary(stats::lm(shuffled ~ x1 + x2, data = dat))$fstatistic[["value"]])
  })
  expect_equal(result$perm, reference, tolerance = 1e-8)
  expect_equal(result$p.value,
               (1 + sum(reference >= result$statistic)) / 21)
  expect_true(result$p.value >= 1 / 21 && result$p.value <= 1)
})

test_that("permutations keep the fitted rows and evaluated response", {
  dat <- make_perm_f_data()
  dat$y[1] <- NA_real_
  set.seed(3)
  result <- pharma_perm_f_test(y ~ x1 + x2, dat, R = 10)
  expect_length(result$perm, 10)
  expect_true(all(is.finite(result$perm)))
  expect_equal(
    result$statistic,
    unname(summary(stats::lm(y ~ x1 + x2, data = dat))$fstatistic[["value"]]),
    tolerance = 1e-8
  )

  limited <- pharma_perm_f_test(y ~ x1 + x2, make_perm_f_data(),
                                    R = 10, subset = x2 > 1)
  limited_reference <- stats::lm(y ~ x1 + x2, data = make_perm_f_data(),
                                 subset = x2 > 1)
  expect_equal(limited$statistic,
               unname(summary(limited_reference)$fstatistic[["value"]]),
               tolerance = 1e-8)

  transformed <- pharma_perm_f_test(log(y) ~ x1 + x2,
                                    make_perm_f_data(), R = 10)
  reference <- stats::lm(log(y) ~ x1 + x2, data = make_perm_f_data())
  expect_equal(transformed$statistic,
               unname(summary(reference)$fstatistic[["value"]]),
               tolerance = 1e-8)
})

test_that("permutation inputs and unsupported models fail explicitly", {
  dat <- make_perm_f_data()
  expect_error(pharma_perm_f_test("y ~ x1", dat), "formula")
  expect_error(pharma_perm_f_test(~x1, dat), "formula")
  expect_error(pharma_perm_f_test(y ~ x1, matrix(1:8, nrow = 4)), "data")
  for (bad in list(NA_real_, Inf, 0, -1, 1.5, c(2, 3), "10", TRUE)) {
    expect_error(pharma_perm_f_test(y ~ x1, dat, R = bad), "R")
  }
  expect_error(pharma_perm_f_test(y ~ 1, dat, R = 2), "predictor")
  expect_error(pharma_perm_f_test(y ~ x1 + x2, dat[c(1, 2, 5), ], R = 2),
               "residual degrees")
  constant <- dat
  constant$y <- rep(1, nrow(dat))
  expect_error(pharma_perm_f_test(y ~ x1 + x2, constant, R = 2),
               "undefined")
  expect_error(pharma_perm_f_test(
    y ~ x1 + x2, dat, R = 2, weights = rep(1, nrow(dat))
  ), "Weights and offsets")
  expect_error(pharma_perm_f_test(y ~ x1 + offset(x2), dat, R = 2),
               "Weights and offsets")
})
