surface_example <- function() {
  grid <- expand.grid(x1 = c(-1, 0, 1), x2 = c(-1, 0, 1),
                      replicate = 1:2)
  grid$y <- 10 + 2 * grid$x1 - 3 * grid$x2 + 4 * grid$x1^2 +
    5 * grid$x2^2 + 6 * grid$x1 * grid$x2 +
    ifelse(grid$replicate == 1, -1, 1)
  grid
}

test_that("response surface recovers all coefficients and residual variance", {
  data <- surface_example()
  fit <- pharma_response_surface(data$x1, data$x2, data$y)

  # Each design point is duplicated with errors -1 and +1. Their mean
  # follows the exact quadratic, leaving SSE 18 and residual df 18 - 6.
  expect_s3_class(fit, "lm")
  expect_equal(unname(stats::coef(fit)), c(10, 2, -3, 4, 5, 6),
               tolerance = 1e-12)
  expect_equal(fit$rank, 6L)
  expect_equal(stats::df.residual(fit), 12L)
  expect_equal(sum(stats::residuals(fit)^2), 18, tolerance = 1e-12)
  expect_equal(unname(summary(fit)$sigma^2), 1.5, tolerance = 1e-12)
  expect_equal(unname(stats::predict(fit,
                                    newdata = data.frame(x1 = 0.5, x2 = -0.5))),
               13.25, tolerance = 1e-12)

  design <- cbind(1, data$x1, data$x2, data$x1^2, data$x2^2,
                  data$x1 * data$x2)
  reference <- solve(crossprod(design), crossprod(design, data$y))
  expect_equal(unname(stats::coef(fit)), as.numeric(reference),
               tolerance = 1e-12)

  backend <- stats::lm(y ~ x1 + x2 + I(x1^2) + I(x2^2) + I(x1 * x2),
                       data = data)
  expect_equal(unname(stats::coef(fit)), unname(stats::coef(backend)),
               tolerance = 1e-12)
})

test_that("response surface rejects singular and underdetermined designs", {
  data <- surface_example()
  unreplicated <- data[data$replicate == 1L, ]
  unreplicated_fit <- pharma_response_surface(
    unreplicated$x1, unreplicated$x2, unreplicated$y
  )
  expect_equal(unreplicated_fit$rank, 6L)
  expect_equal(stats::df.residual(unreplicated_fit), 3L)

  expect_error(pharma_response_surface(1:10, 11:20, 1:10),
               "six estimable columns")
  expect_error(pharma_response_surface(data$x1, data$x1, data$y),
               "six estimable columns")
  expect_error(pharma_response_surface(data$x1[1:6], data$x2[1:6],
                                       data$y[1:6]), "at least seven")
  expect_error(pharma_response_surface(data$x1[-1L], data$x2, data$y),
               "equal lengths")
})

test_that("response surface checks values and fit population", {
  data <- surface_example()
  expect_error(pharma_response_surface(factor(data$x1), data$x2, data$y),
               "finite numeric vectors")
  bad <- data$x1
  bad[1L] <- NA_real_
  expect_error(pharma_response_surface(bad, data$x2, data$y),
               "finite numeric vectors")
  bad[1L] <- Inf
  expect_error(pharma_response_surface(bad, data$x2, data$y),
               "finite numeric vectors")
  expect_error(pharma_response_surface(data$x1, data$x2, data$y,
                                       subset = x1 > 0), "not supported")
  expect_error(pharma_response_surface(data$x1, data$x2, data$y,
                                       weights = rep(1, nrow(data))),
               "not supported")
  expect_error(pharma_response_surface(data$x1, data$x2, data$y,
                                       na.action = stats::na.omit),
               "not supported")
  expect_error(pharma_response_surface(data$x1, data$x2, data$y,
                                       offset = rep(0, nrow(data))),
               "not supported")
  expect_error(pharma_response_surface(data$x1, data$x2, data$y, TRUE),
               "must be named")
})
