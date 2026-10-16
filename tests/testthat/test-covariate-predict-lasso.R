testthat::local_edition(3)

prediction_lasso_fixture <- function(method = "mean", literal = FALSE) {
  block <- data.frame(
    x1 = c(-1, -1, 1, 1, NA, NA), x2 = c(-1, 1, -1, 1, -1, 1),
    y = c(-2, -2, 2, 2, 0, 0)
  )
  data <- block[rep(seq_len(6), 3), ]
  if (literal) names(data) <- c("dose + amount", "(Intercept)", "response value")
  screen_covariates_lasso_imputed(data, names(data)[3], names(data)[1:2],
    lambda = c(2, 1, 0.5), method = method, k = 2,
    foldid = rep(1:3, each = 6)
  )
}

test_that("saved predictions match analytic values at selected and reordered penalties", {
  new <- data.frame(x2 = c(1, -1, 1), x1 = c(NA, 1, -1), row.names = c("a", "b", "c"))
  for (method in c("mean", "median", "knn")) {
    result <- prediction_lasso_fixture(method)
    original <- result
    predicted <- predict_lasso_imputed(result, new)
    expect_type(predicted, "double")
    expect_equal(dim(predicted), c(3L, 1L))
    expect_equal(as.vector(predicted), c(0, 1, -1) * (2 - 0.5 * sqrt(3 / 2)), tolerance = 1e-7)
    expect_identical(dimnames(predicted), list(rownames(new), "lambda_3"))
    penalties <- c(0.5, 2, 1)
    all <- predict_lasso_imputed(result, new, lambda = penalties)
    expect_equal(unname(all), outer(c(0, 1, -1), pmax(2 - penalties * sqrt(3 / 2), 0)), tolerance = 1e-7)
    expect_identical(colnames(all), c("lambda_3", "lambda_1", "lambda_2"))
    expect_identical(rownames(all), rownames(new))
    expect_identical(result, original)
  }
})

test_that("the chosen saved imputer controls asymmetric future replacements", {
  data <- data.frame(y = 1:9, x1 = c(1, NA, 2, 3, NA, 9, 8, NA, 20), x2 = rep(c(-1, 1, 0), 3))
  replacements <- c(mean = 43 / 6, median = 11 / 2, knn = 2)
  for (method in names(replacements)) {
    result <- screen_covariates_lasso_imputed(data, "y", c("x1", "x2"),
      c(1, 0.1),
      method = method, k = 1, foldid = rep(1:3, each = 3)
    )
    new <- data.frame(x1 = c(NA, 100), x2 = c(1, -1))
    completed <- cbind(1, c(replacements[[method]], 100), c(1, -1))
    # Independent saved-model calculation using the hand-derived replacement.
    expected <- completed %*% as.matrix(stats::coef(result$fit))
    expect_equal(unname(predict_lasso_imputed(result, new, result$cv$lambda)), unname(expected))
    new$x1[2] <- -1000
    expect_equal(as.vector(predict_lasso_imputed(result, new[1, ], result$cv$lambda)), as.vector(expected[1, ]))
    expect_equal(as.vector(predict_lasso_imputed(result, new, result$cv$lambda)[1, ]), as.vector(expected[1, ]))
  }
})

test_that("literal names, extra columns, singleton and empty rows preserve the contract", {
  result <- prediction_lasso_fixture("knn", literal = TRUE)
  new <- data.frame(a = c(NA, 1), b = c(1, -1), junk = I(list(list("anything"), NULL)))
  names(new)[1:2] <- result$covariates
  original <- new
  expected <- c(0, 1) * (2 - 0.5 * sqrt(3 / 2))
  expect_identical(result$selected, "dose + amount")
  expect_equal(as.vector(predict_lasso_imputed(result, new[c(3, 2, 1)])), expected, tolerance = 1e-7)
  one <- predict_lasso_imputed(result, new[2, , drop = FALSE], c(1, 0.5))
  expect_equal(dim(one), c(1L, 2L))
  expect_equal(as.vector(one), 2 - c(1, 0.5) * sqrt(3 / 2), tolerance = 1e-7)
  expect_identical(rownames(one), rownames(new)[2])
  empty <- predict_lasso_imputed(result, new[FALSE, ], c(1, 0.5))
  expect_equal(dim(empty), c(0L, 2L))
  expect_identical(colnames(empty), c("lambda_2", "lambda_3"))
  expect_type(empty, "double")
  expect_identical(new, original)
  # A zero coefficient does not remove that candidate from the training schema.
  expect_error(predict_lasso_imputed(result, new[result$selected]), "Prediction data:.*not found")
  for (method in c("mean", "median")) {
    simple <- prediction_lasso_fixture(method)
    wholly_missing <- data.frame(x1 = c(NA_real_, NaN), x2 = c(NA_real_, NA))
    expect_equal(as.vector(predict_lasso_imputed(simple, wholly_missing)), c(0, 0), tolerance = 1e-7)
  }
})

test_that("RDS and historical mean/median metadata produce the same predictions", {
  path <- tempfile(fileext = ".rds")
  on.exit(unlink(path), add = TRUE)
  new <- data.frame(x1 = c(NA, 1), x2 = c(1, -1))
  for (method in c("mean", "median", "knn")) {
    result <- prediction_lasso_fixture(method)
    saveRDS(result, path)
    expect_identical(predict_lasso_imputed(readRDS(path), new), predict_lasso_imputed(result, new))
    if (method != "knn") {
      old <- result
      old$method <- NULL
      old$covariates <- NULL
      expect_identical(predict_lasso_imputed(old, new), predict_lasso_imputed(result, new))
    }
  }
})

test_that("prediction does not fit imputers or models, or rescale new batches", {
  mean_result <- prediction_lasso_fixture()
  knn_result <- prediction_lasso_fixture("knn")
  local_mocked_bindings(
    fit_imputation = function(...) stop("Unexpected imputation fitting"),
    fit_knn_imputation = function(...) stop("Unexpected donor fitting"),
    center_scale = function(...) stop("Unexpected scaling"),
    .package = "PharmaStatsR"
  )
  local_mocked_bindings(glmnet = function(...) stop("Unexpected model refit"), .package = "glmnet")
  new <- data.frame(x1 = c(NA, 1000), x2 = c(1, -1))
  for (result in list(mean_result, knn_result)) {
    expect_equal(as.vector(predict_lasso_imputed(result, new)), c(0, 1000) * (2 - 0.5 * sqrt(3 / 2)), tolerance = 1e-7)
    expect_equal(as.vector(predict_lasso_imputed(result, new[1, ])), 0, tolerance = 1e-7)
  }
})

test_that("new data and unsupported penalties fail clearly", {
  result <- prediction_lasso_fixture()
  new <- data.frame(x1 = NA_real_, x2 = 1)
  for (penalty in list(numeric(), NA_real_, Inf, c(1, 1), matrix(1), "1", TRUE)) {
    expect_error(predict_lasso_imputed(result, new, penalty), "distinct fitted penalties")
  }
  for (penalty in list(0, -1, 0.75, 3)) {
    expect_error(predict_lasso_imputed(result, new, penalty), "value in.*cv.*lambda")
  }
  expect_error(predict_lasso_imputed(result, as.matrix(new)), "Prediction data:.*data.frame")
  changed <- new
  changed$x1 <- "1"
  expect_error(predict_lasso_imputed(result, changed), "Prediction data:.*numeric")
  changed$x1 <- Inf
  expect_error(predict_lasso_imputed(result, changed), "Prediction data:.*infinite")
  changed$x1 <- .Machine$double.xmax
  expect_error(predict_lasso_imputed(result, changed), "Prediction values must be finite")
  names(changed) <- c("x1", "x1")
  expect_error(predict_lasso_imputed(result, changed), "Prediction data:.*unique")
  knn <- prediction_lasso_fixture("knn")
  missing <- data.frame(x1 = NA_real_, x2 = NA_real_)
  expect_error(predict_lasso_imputed(knn, missing), "Prediction data: Target 'x1'.*no comparable training donors")
})

test_that("inconsistent saved prediction structures cannot silently change the model", {
  result <- prediction_lasso_fixture()
  new <- data.frame(x1 = 1, x2 = 1)
  expect_error(predict_lasso_imputed(NULL, new), "Invalid screening result")
  for (field in c("fit", "imputation", "cv", "lambda.min", "method", "covariates")) {
    changed <- result
    changed[[field]] <- NULL
    expect_error(predict_lasso_imputed(changed, new), "Invalid screening result")
  }
  changed <- result
  changed$covariates <- rev(changed$covariates)
  expect_error(predict_lasso_imputed(changed, new), "predictor order")
  changed <- result
  changed$method <- "median"
  expect_error(predict_lasso_imputed(changed, new), "replacement table")
  changed <- result
  changed$imputation$value[1] <- Inf
  expect_error(predict_lasso_imputed(changed, new), "finite real numbers")
  changed <- result
  changed$cv$lambda <- c(0.5, 1, 2)
  expect_error(predict_lasso_imputed(changed, new), "strictly decreasing")
  changed <- result
  changed$lambda.min <- 0.75
  expect_error(predict_lasso_imputed(changed, new), "selected penalty")
  changed <- result
  changed$fit$lambda[1] <- 3
  expect_error(predict_lasso_imputed(changed, new), "model path")
  changed <- result
  rownames(changed$fit$beta) <- rev(rownames(changed$fit$beta))
  expect_error(predict_lasso_imputed(changed, new), "model coefficients")
  changed <- result
  changed$fit$a0[1] <- NaN
  expect_error(predict_lasso_imputed(changed, new), "nonfinite")
  changed <- result
  changed$fit <- list()
  expect_error(predict_lasso_imputed(changed, new), "Gaussian model")
  changed <- prediction_lasso_fixture("knn")
  changed$imputation$vars <- rev(changed$covariates)
  expect_error(predict_lasso_imputed(changed, new), "donor model targets")
})
