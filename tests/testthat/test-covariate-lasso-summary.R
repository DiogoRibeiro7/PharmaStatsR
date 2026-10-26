local_edition(3)

lasso_summary_data <- function() {
  block <- data.frame(
    x1 = c(-1, -1, 1, 1, NA, NA), x2 = c(-1, 1, -1, 1, -1, 1),
    y = c(-2, -2, 2, 2, 0, 0)
  )
  block[rep(seq_len(6), 3), ]
}

lasso_summary_fit <- function(method = "mean", ...) {
  screen_covariates_lasso_imputed(
    lasso_summary_data(), "y", c("x1", "x2"),
    lambda = c(2, 1, 0.5), method = method, k = 2,
    foldid = rep(1:3, each = 6), ...
  )
}

test_that("summaries expose independent soft-threshold coefficients and tuning errors", {
  for (method in c("mean", "median", "knn")) {
    fit <- lasso_summary_fit(method)
    original <- fit
    result <- summary(fit)
    expect_s3_class(fit, c("pharma_lasso_imputed", "list"))
    expect_s3_class(result, "summary.pharma_lasso_imputed", exact = TRUE)
    # Completed x1 has variance 2/3 and is orthogonal to x2. With alpha=1,
    # its raw-scale coefficient is 2 - lambda/sqrt(2/3); others are zero.
    expect_equal(as.vector(coef(result)), c(0, 2 - sqrt(3 / 8), 0), tolerance = 1e-7)
    expect_identical(colnames(coef(result)), "Estimate")
    expect_identical(rownames(coef(result)), c("(Intercept)", "x1", "x2"))
    expect_identical(result$lambda.min, 0.5)
    expect_equal(result$mse.min, 1 / 4, tolerance = 1e-7)
    expect_equal(result$cv$mse, c(8 / 3, 1, 1 / 4), tolerance = 1e-7)
    expect_identical(result$cv, fit$cv)
    expect_identical(result$alpha, 1)
    expect_identical(result$method, method)
    expect_false(result$encoded)
    expect_identical(c(result$nobs, result$n.excluded, result$nfolds), c(18L, 0L, 3L))
    expect_identical(result$covariates, c("x1", "x2"))
    expect_identical(result$selected, "x1")
    expect_identical(result$selected_columns, "x1")
    expect_identical(fit, original)
  }
})

test_that("summaries count excluded rows and preserve tied intercept-only selection", {
  data <- data.frame(y = c(NA, 1:6), x1 = c(NA, 1, NA, 3, 4, 5, 6), x2 = c(NA, rep(0:1, 3)))
  fit <- screen_covariates_lasso_imputed(data, "y", c("x1", "x2"),
    lambda = c(1e4, 1e5), foldid = c(1, 1, 2, 2, 3, 3, 3)
  )
  result <- summary(fit)
  expect_identical(c(result$nobs, result$n.excluded, result$nfolds), c(6L, 1L, 3L))
  expect_identical(result$lambda.min, 1e5)
  expect_equal(as.vector(coef(result)), c(3.5, 0, 0))
  # Unequal held-out folds give errors (9,4,1,4,9,16); row-weighted MSE=43/6.
  expect_equal(result$mse.min, 43 / 6)
  expect_identical(result$selected, character())
  expect_identical(result$selected_columns, character())
  printed <- capture.output(print(result))
  expect_true(any(grepl("Selected raw covariates: (none)", printed, fixed = TRUE)))
})

test_that("encoded summaries distinguish raw candidates from design coefficients", {
  data <- lasso_summary_data()
  data$group <- rep(c("A", "B"), 9)
  data$y <- data$y + rep(c(-3, 3), 9)
  for (method in c("mean", "knn")) {
    fit <- screen_covariates_lasso_imputed(data, "y", c("x1", "group"),
      lambda = c(4, 2, 1, 0.5), method = method, k = 2,
      encode = TRUE, foldid = rep(1:3, each = 6)
    )
    result <- summary(fit)
    expect_true(result$encoded)
    expect_identical(result$selected, c("x1", "group"))
    expect_identical(rownames(coef(result)), c("(Intercept)", "x1", "groupA", "groupB"))
    expect_identical(result$selected_columns, fit$selected_columns)
    expect_equal(coef(result)["x1", 1], 2 - sqrt(3 / 8), tolerance = 1e-6)
    # Individual redundant indicators need not be unique; their contrast is 5.
    expect_equal(coef(result)["groupB", 1] - coef(result)["groupA", 1], 5, tolerance = 1e-6)
    expect_equal(result$cv$mse, c(35 / 3, 20 / 3, 2, 0.5), tolerance = 1e-6)
    expect_equal(result$mse.min, 0.5, tolerance = 1e-6)
  }
})

test_that("literal coefficient labels and non-LASSO mixing settings survive summaries", {
  data <- lasso_summary_data()
  names(data)[1:2] <- c("dose + amount", "(Intercept)")
  for (alpha in c(0, 0.5, 1)) {
    fit <- screen_covariates_lasso_imputed(data, "y", names(data)[1:2],
      lambda = c(2, 1, 0.5), alpha = alpha, foldid = rep(1:3, each = 6)
    )
    result <- summary(fit)
    expect_identical(result$alpha, alpha)
    expect_identical(rownames(coef(result)), c("(Intercept)", "dose + amount", "(Intercept)"))
    expected <- as.matrix(stats::coef(fit$fit))[, match(fit$lambda.min, fit$cv$lambda)]
    expect_identical(as.vector(coef(result)), unname(expected))
    expect_identical(result$selected, fit$selected)
  }
})

test_that("saved and legacy summaries preserve predictions and never refit", {
  fit <- lasso_summary_fit("knn")
  mean_fit <- lasso_summary_fit()
  path <- tempfile(fileext = ".rds")
  on.exit(unlink(path))
  saveRDS(fit, path)
  restored <- readRDS(path)
  expected <- summary(fit)
  expect_identical(summary(restored), expected)
  future <- data.frame(x1 = c(NA, 1), x2 = c(1, -1))
  expect_identical(predict_lasso_imputed(restored, future), predict_lasso_imputed(fit, future))
  legacy <- unclass(mean_fit)
  legacy$method <- legacy$covariates <- NULL
  class(legacy) <- c("pharma_lasso_imputed", "list")
  expect_identical(summary(legacy), summary(mean_fit))
  local_mocked_bindings(
    fit_imputation = function(...) stop("Unexpected imputer fitting"),
    fit_knn_imputation = function(...) stop("Unexpected donor fitting"),
    fit_encoding = function(...) stop("Unexpected encoding fitting"),
    .package = "PharmaStatsR"
  )
  local_mocked_bindings(glmnet = function(...) stop("Unexpected model refit"), .package = "glmnet")
  set.seed(731)
  seed <- .Random.seed
  expect_identical(summary(restored), expected)
  expect_identical(.Random.seed, seed)
  saveRDS(expected, path)
  expect_identical(coef(readRDS(path)), expected$coefficients)
})

test_that("printing is informative and returns the unchanged summary invisibly", {
  result <- summary(lasso_summary_fit())
  original <- result
  text <- capture.output(printed <- withVisible(print(result, digits = 6)))
  expect_false(printed$visible)
  expect_identical(printed$value, result)
  expect_identical(result, original)
  for (heading in c(
    "Imputed Gaussian LASSO", "18 retained, 0 excluded; folds: 3",
    "Imputation: mean; categorical encoding: no", "selected lambda: 0.5",
    "Penalized coefficients", "Estimate", "Selected raw covariates: \"x1\"",
    "Minimum held-out MSE: 0.25", "CV MSE is tuning error"
  )) {
    expect_true(any(grepl(heading, text, fixed = TRUE)), info = heading)
  }
  expect_false(any(grepl("Std. Error|Pr\\(>|Signif. codes|R-squared|F-statistic", text)))
  expect_false(inherits(result, "summary.lm"))
})

test_that("incomplete or inconsistent summary metadata fails clearly", {
  fit <- lasso_summary_fit()
  for (bad in list(NULL, c(1, NA, 0.25), c(1, Inf, 0.25), c(1, -1, 0.25), letters[1:3])) {
    changed <- fit
    changed$cv$mse <- bad
    expect_error(summary(changed), "CV errors must be")
  }
  changed <- fit
  changed$lambda.min <- 2
  expect_error(summary(changed), "minimum CV error")
  for (bad in list(NULL, NA, Inf, -1, 2, TRUE)) {
    changed <- fit
    changed$alpha <- bad
    expect_error(summary(changed), "mixing parameter")
  }
  for (bad in list(NULL, rep(1, 18), rep(1:3, 5), c(Inf, rep(1:3, 6)), letters[1:3])) {
    changed <- fit
    changed$foldid <- bad
    expect_error(summary(changed), "fold labels")
  }
  for (bad in list(NULL, "unknown", c("x1", "x1"), NA_character_)) {
    changed <- fit
    changed$selected <- bad
    expect_error(summary(changed), "selected candidates")
  }
  changed <- fit
  changed$fit <- NULL
  expect_error(summary(changed), "Invalid screening result")
  expect_error(summary(fit, correlation = TRUE), "No additional arguments")
})
