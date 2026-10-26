local_edition(3)

lasso_methods_data <- function() {
  block <- data.frame(
    x1 = c(-1, -1, 1, 1, NA, NA), x2 = c(-1, 1, -1, 1, -1, 1),
    y = c(-2, -2, 2, 2, 0, 0)
  )
  block[rep(seq_len(6), 3), ]
}

lasso_methods_fit <- function(method = "mean", ...) {
  screen_covariates_lasso_imputed(lasso_methods_data(), "y", c("x1", "x2"),
    lambda = c(2, 1, 0.5), method = method, k = 2,
    foldid = rep(1:3, each = 6), ...
  )
}

test_that("standard methods preserve analytic coefficients and predictions at requested penalties", {
  penalties <- c(0.5, 2, 1)
  # Independent soft-threshold solution: imputed Var(x1)=2/3, x2 orthogonal.
  slopes <- pmax(2 - penalties * sqrt(3 / 2), 0)
  expected <- rbind(0, slopes, 0)
  dimnames(expected) <- list(c("(Intercept)", "x1", "x2"), c("lambda_3", "lambda_1", "lambda_2"))
  future <- data.frame(x2 = c(1, -1, 1), x1 = c(NA, 1, -1), row.names = c("a", "b", "c"))
  predictions <- outer(c(0, 1, -1), slopes)
  dimnames(predictions) <- list(rownames(future), colnames(expected))
  for (method in c("mean", "median", "knn")) {
    fit <- lasso_methods_fit(method)
    original <- fit
    input <- future
    expect_equal(coef(fit, lambda = penalties), expected, tolerance = 1e-7)
    expect_equal(predict(fit, future, lambda = penalties), predictions, tolerance = 1e-7)
    expect_identical(coef(fit), coef(fit, lambda = penalties)[, 1, drop = FALSE])
    expect_identical(as.vector(coef(fit)), as.vector(coef(summary(fit))))
    expect_identical(predict(fit, future), predict_lasso_imputed(fit, future))
    expect_identical(dim(predict(fit, future[2, , drop = FALSE])), c(1L, 1L))
    expect_identical(predict(fit, future[2, , drop = FALSE]), predict(fit, future)[2, , drop = FALSE])
    empty <- predict(fit, future[FALSE, ], lambda = penalties)
    expect_identical(dim(empty), c(0L, 3L))
    expect_identical(colnames(empty), colnames(expected))
    expect_identical(fit, original)
    expect_identical(future, input)
  }
})

test_that("encoded methods retain raw-data prediction and identifiable coefficient contrasts", {
  data <- lasso_methods_data()
  data$group <- rep(c("A", "B"), 9)
  data$y <- data$y + rep(c(-3, 3), 9)
  beta <- 2 - sqrt(3 / 8)
  future <- data.frame(group = c("B", "A", "B"), x1 = c(NA, 1, -1))
  for (method in c("mean", "median", "knn")) {
    fit <- screen_covariates_lasso_imputed(data, "y", c("x1", "group"),
      lambda = c(4, 2, 1, 0.5), encode = TRUE, method = method, k = 2,
      foldid = rep(1:3, each = 6)
    )
    coefficients <- coef(fit, lambda = c(0.5, 4))
    expect_identical(rownames(coefficients), c("(Intercept)", "x1", "groupA", "groupB"))
    expect_identical(colnames(coefficients), c("lambda_4", "lambda_1"))
    expect_equal(coefficients["x1", 1], beta, tolerance = 1e-6)
    # Individual redundant indicators need not be unique; these sums are fixed.
    expect_equal(coefficients[1, 1] + coefficients["groupA", 1], -2.5, tolerance = 1e-6)
    expect_equal(coefficients[1, 1] + coefficients["groupB", 1], 2.5, tolerance = 1e-6)
    expect_equal(as.vector(coefficients[, 2]), rep(0, 4), tolerance = 1e-6)
    expected <- cbind(c(2.5, beta - 2.5, -beta + 2.5), 0)
    dimnames(expected) <- list(rownames(future), c("lambda_4", "lambda_1"))
    prediction <- withr::with_options(
      list(contrasts = c("contr.sum", "contr.poly")),
      predict(fit, future, lambda = c(0.5, 4))
    )
    expect_equal(prediction, expected, tolerance = 1e-6)
    expect_identical(predict(fit, future), predict_lasso_imputed(fit, future))
    unknown <- future
    unknown$group[1] <- "unknown"
    expect_error(predict(fit, unknown), "Prediction data:")
  }
})

test_that("literal names and non-LASSO mixing settings select saved coefficient columns", {
  data <- lasso_methods_data()
  names(data)[1:2] <- c("dose + amount", "(Intercept)")
  for (alpha in c(0, 0.5, 1)) {
    fit <- screen_covariates_lasso_imputed(data, "y", names(data)[1:2],
      lambda = c(2, 1, 0.5), alpha = alpha, foldid = rep(1:3, each = 6)
    )
    result <- coef(fit, lambda = c(0.5, 2))
    expect_identical(rownames(result), c("(Intercept)", "dose + amount", "(Intercept)"))
    expect_identical(unname(result), unname(as.matrix(stats::coef(fit$fit))[, c(3, 1), drop = FALSE]))
    expect_identical(predict(fit, data[1:2]), predict_lasso_imputed(fit, data[1:2]))
  }
})

test_that("saved and legacy methods do not fit, interpolate, or draw random numbers", {
  fit <- lasso_methods_fit("knn")
  future <- data.frame(x1 = c(NA, 1), x2 = c(1, -1))
  expected_coef <- coef(fit)
  expected_prediction <- predict(fit, future)
  path <- tempfile(fileext = ".rds")
  on.exit(unlink(path))
  saveRDS(fit, path)
  restored <- readRDS(path)
  mean_fit <- lasso_methods_fit()
  legacy <- unclass(mean_fit)
  legacy$method <- legacy$covariates <- NULL
  class(legacy) <- c("pharma_lasso_imputed", "list")
  expect_identical(coef(legacy), coef(mean_fit))
  expect_identical(predict(legacy, future), predict(mean_fit, future))
  local_mocked_bindings(
    fit_imputation = function(...) stop("Unexpected imputer fitting"),
    fit_knn_imputation = function(...) stop("Unexpected donor fitting"),
    fit_encoding = function(...) stop("Unexpected encoding fitting"),
    .package = "PharmaStatsR"
  )
  local_mocked_bindings(glmnet = function(...) stop("Unexpected model fitting"), .package = "glmnet")
  set.seed(728)
  seed <- .Random.seed
  expect_identical(coef(restored), expected_coef)
  expect_identical(predict(restored, future), expected_prediction)
  expect_identical(.Random.seed, seed)
  expect_identical(restored, fit)
})

test_that("standard methods reject unsupported requests and inconsistent saved inputs", {
  fit <- lasso_methods_fit()
  future <- data.frame(x1 = NA_real_, x2 = 1)
  for (bad in list(numeric(), c(1, 1), NA_real_, NaN, Inf, TRUE, "1", matrix(1), -1, 0, 0.75, 0.5 + .Machine$double.eps)) {
    expect_error(coef(fit, lambda = bad), "lambda")
    expect_error(predict(fit, future, lambda = bad), "lambda")
  }
  expect_error(coef(fit, s = 0.5), "No additional arguments")
  expect_error(coef(fit, exact = TRUE), "No additional arguments")
  expect_error(predict(fit, future, type = "response"), "No additional arguments")
  expect_error(predict(fit, future, interval = "prediction"), "No additional arguments")
  expect_error(predict(fit), "newdata")
  expect_error(predict(fit, future["x1"]), "Prediction data:")
  fit$fit <- NULL
  expect_error(coef(fit), "Invalid screening result")
  expect_error(predict(fit, future), "Invalid screening result")
})
