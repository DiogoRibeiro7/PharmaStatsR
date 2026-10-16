local_edition(3)

imputed_lasso_orthogonal <- function() {
  block <- data.frame(
    x1 = c(-1, -1, 1, 1, NA, NA), x2 = c(-1, 1, -1, 1, -1, 1),
    y = c(-2, -2, 2, 2, 0, 0)
  )
  data <- block[rep(seq_len(6), 3), ]
  rownames(data) <- paste0("row-", seq_len(nrow(data)))
  data
}

imputed_lasso_asymmetric <- function() {
  data.frame(
    subject = rep(c("A", "B", "C"), each = 3), y = 1:9,
    x1 = c(1, NA, 2, 3, NA, 9, 8, NA, 20), x2 = rep(c(-1, 1, 0), 3)
  )
}

test_that("orthogonal LASSO has fixed soft-threshold coefficients and MSE", {
  data <- imputed_lasso_orthogonal()
  original <- data
  lambda <- c(2, 1, 0.5)
  result <- screen_covariates_lasso_imputed(data, "y", c("x1", "x2"),
    lambda = lambda, foldid = rep(1:3, each = 6)
  )
  # Imputed x1 has mean 0 and population variance 2/3; x2 has variance 1.
  # The columns are orthogonal. With standardized x, beta1 is
  # max(2 - lambda / sqrt(2/3), 0), while the intercept and beta2 are zero.
  slopes <- pmax(2 - lambda * sqrt(3 / 2), 0)
  expected_coefficients <- rbind(rep(0, 3), slopes, rep(0, 3))
  expected_predictions <- outer(rep(c(-1, -1, 1, 1, 0, 0), 3), slopes)
  expect_equal(unname(as.matrix(stats::coef(result$fit))), unname(expected_coefficients),
    tolerance = 1e-7
  )
  expect_equal(unname(result$predictions), expected_predictions, tolerance = 1e-7)
  expect_equal(result$cv$mse, c(8 / 3, 1, 1 / 4), tolerance = 1e-7)
  expect_identical(result$cv$lambda, lambda)
  expect_identical(result$lambda.min, 0.5)
  expect_identical(result$selected, "x1")
  expect_identical(result$foldid, rep(1:3, each = 6))
  expect_identical(rownames(result$predictions), rownames(data))
  expect_equal(result$imputation$value, c(0, 0))
  expect_identical(data, original)
})

test_that("unequal folds use observation-weighted MSE and largest-penalty ties", {
  data <- data.frame(y = 1:6, x1 = c(1, NA, 3, 4, 5, 6), x2 = rep(0:1, 3))
  result <- screen_covariates_lasso_imputed(data, "y", c("x1", "x2"),
    lambda = c(1e4, 1e5), foldid = c(1, 2, 2, 3, 3, 3)
  )
  # Both penalties give intercept-only fits. Training means are 4, 4, and 2.
  # Squared errors are 9, 4, 1, 4, 9, 16, with sum 43 across six rows.
  expected <- c(4, 4, 4, 2, 2, 2)
  expect_equal(unname(result$predictions), unname(cbind(expected, expected)))
  expect_equal(result$cv$mse, rep(43 / 6, 2))
  expect_gt(abs(result$cv$mse[1] - mean(c(9, 5 / 2, 29 / 3))), 0.1)
  expect_identical(result$cv$lambda, c(1e5, 1e4))
  expect_identical(result$lambda.min, 1e5)
  expect_identical(result$selected, character(0))
})

test_that("each training fold learns its own mean or median", {
  data <- imputed_lasso_asymmetric()
  for (method in c("mean", "median")) {
    result <- screen_covariates_lasso_imputed(data, "y", c("x1", "x2"),
      lambda = c(1, 0.1), method = method, id = "subject",
      foldid = rep(c(10, 20, 30), each = 3)
    )
    expected <- if (method == "mean") c(10, 31 / 4, 15 / 4) else c(17 / 2, 5, 5 / 2)
    expect_equal(
      vapply(result$fold_imputation, function(p) p$value[1], numeric(1)),
      stats::setNames(expected, as.character(1:3))
    )
    expect_equal(result$imputation$value[1], if (method == "mean") 43 / 6 else 11 / 2)
    for (fold in 1:3) {
      held <- result$foldid == fold
      train <- data[!held, ]
      validation <- data[held, ]
      train$x1[is.na(train$x1)] <- expected[fold]
      validation$x1[is.na(validation$x1)] <- expected[fold]
      direct <- glmnet::glmnet(as.matrix(train[c("x1", "x2")]), train$y,
        lambda = c(1, 0.1), family = "gaussian", alpha = 1,
        standardize = TRUE, intercept = TRUE
      )
      predicted <- stats::predict(direct,
        newx = as.matrix(validation[c("x1", "x2")]), s = c(1, 0.1)
      )
      expect_equal(unname(result$predictions[held, ]), unname(predicted))
      expect_identical(result$fold_imputation[[fold]]$method, rep(method, 2))
    }
  }
})

test_that("held-out data cannot change its own fitted preprocessing or model", {
  data <- imputed_lasso_asymmetric()
  fit <- function(data) {
    screen_covariates_lasso_imputed(data, "y", c("x1", "x2"),
      lambda = c(1, 0.1), id = "subject", foldid = rep(1:3, each = 3)
    )
  }
  baseline <- fit(data)
  changed <- data
  changed$y[1:3] <- changed$y[1:3] + 100
  perturbed_response <- fit(changed)
  expect_identical(perturbed_response$fold_imputation[[1]], baseline$fold_imputation[[1]])
  expect_equal(perturbed_response$predictions[1:3, ], baseline$predictions[1:3, ])
  expect_false(isTRUE(all.equal(perturbed_response$cv$mse, baseline$cv$mse)))
  changed <- data
  changed$x1[1] <- 999
  perturbed_predictor <- fit(changed)
  expect_identical(perturbed_predictor$fold_imputation[[1]], baseline$fold_imputation[[1]])
  expect_equal(perturbed_predictor$predictions[2:3, ], baseline$predictions[2:3, ])
  expect_false(isTRUE(all.equal(perturbed_predictor$predictions[1, ], baseline$predictions[1, ])))
})

test_that("only missing responses are excluded and original rows stay aligned", {
  data <- imputed_lasso_asymmetric()
  data$y[2] <- NA_real_
  data$x1[2] <- Inf # Ignored with the missing response.
  data$subject[2] <- NA_character_
  data$x1[4:6] <- NA_real_ # A completely missing held-out predictor is allowed.
  rownames(data) <- paste0("case-", 9:1)
  set.seed(22)
  before <- .Random.seed
  result <- screen_covariates_lasso_imputed(data, "y", c("x1", "x2"),
    lambda = c(1, 0.1), id = "subject", nfolds = 2,
    foldid = rep(c(10, 20, 30), each = 3)
  )
  expect_identical(.Random.seed, before)
  expect_identical(result$foldid, c(1L, NA_integer_, 1L, 2L, 2L, 2L, 3L, 3L, 3L))
  expect_true(all(is.na(result$predictions[2, ])))
  expect_true(all(is.finite(result$predictions[-2, ])))
  expect_identical(rownames(result$predictions), rownames(data))
  expect_equal(result$cv$mse, unname(colMeans((result$predictions[-2, ] - data$y[-2])^2)))
  expect_equal(result$fold_imputation[[2]]$value[1], 31 / 4)
})

test_that("random folds preserve subjects and reproduce with the same seed", {
  data <- imputed_lasso_orthogonal()
  data$subject <- rep(seq_len(9), each = 2)
  fit <- function() {
    screen_covariates_lasso_imputed(data, "y", c("x1", "x2"),
      lambda = c(2, 1, 0.5), id = "subject", nfolds = 3
    )
  }
  set.seed(48)
  first <- fit()
  set.seed(48)
  second <- fit()
  expect_identical(first$foldid, second$foldid)
  expect_equal(first$predictions, second$predictions)
  expect_true(all(vapply(split(first$foldid, data$subject), function(x) {
    length(unique(x)) == 1L
  }, logical(1))))
  expect_equal(as.integer(table(first$foldid[!duplicated(data$subject)])), rep(3L, 3))
})

test_that("saved final imputation and model support literal names and new rows", {
  data <- imputed_lasso_orthogonal()
  names(data) <- c("dose + amount", "(Intercept)", "outcome")
  vars <- names(data)[1:2]
  result <- screen_covariates_lasso_imputed(data, "outcome", vars,
    lambda = c(2, 1, 0.5), foldid = rep(1:3, each = 6)
  )
  expect_identical(result$selected, "dose + amount")
  file <- tempfile(fileext = ".rds")
  on.exit(unlink(file), add = TRUE)
  saveRDS(result, file)
  saved <- readRDS(file)
  new <- data.frame(x = c(NA, 1, -1), z = c(1, -1, 1))
  names(new) <- vars
  completed <- apply_imputation(new[rev(vars)], saved$imputation)
  predicted <- stats::predict(saved$fit,
    newx = as.matrix(completed[saved$imputation$var]), s = saved$lambda.min
  )
  expect_equal(as.vector(predicted), c(0, 1, -1) * (2 - 0.5 * sqrt(3 / 2)), tolerance = 1e-7)
  expect_identical(saved$fold_imputation, result$fold_imputation)
})

test_that("elastic-net and ridge fits retain their backend settings", {
  data <- imputed_lasso_orthogonal()
  for (alpha in c(0, 0.5)) {
    result <- screen_covariates_lasso_imputed(data, "y", c("x1", "x2"),
      lambda = c(2, 1, 0.5), alpha = alpha, foldid = rep(1:3, each = 6)
    )
    completed <- data
    completed$x1[is.na(completed$x1)] <- 0
    direct <- glmnet::glmnet(as.matrix(completed[c("x1", "x2")]), completed$y,
      lambda = c(2, 1, 0.5), alpha = alpha, standardize = TRUE, intercept = TRUE
    )
    expect_equal(as.matrix(stats::coef(result$fit)), as.matrix(stats::coef(direct)))
    expect_identical(result$alpha, alpha)
    expect_true(all(is.finite(result$predictions)))
  }
})

test_that("input and penalty boundaries fail before fitting", {
  data <- imputed_lasso_orthogonal()
  fit <- function(data = imputed_lasso_orthogonal(), ...) {
    screen_covariates_lasso_imputed(data, "y", c("x1", "x2"), ...)
  }
  for (lambda in list(NULL, 1, c(1, 1), c(0, 1), c(-1, 1), c(NA, 1), c(Inf, 1), c("1", "2"), matrix(1:2))) {
    expect_error(fit(lambda = lambda), "distinct finite positive penalties")
  }
  for (alpha in list(-1, 2, NA_real_, Inf, "1", c(0, 1))) {
    expect_error(fit(lambda = c(1, 0.1), alpha = alpha), "finite number between")
  }
  expect_error(fit(as.matrix(data), lambda = c(1, 0.1)), "data.frame")
  expect_error(fit(lambda = c(1, 0.1), method = "mode"), "arg")
  expect_error(fit(lambda = c(1, 0.1), id = "x1"), "distinct from")
  expect_error(fit(lambda = c(1, 0.1), id = "missing"), "identifier column")
  expect_error(screen_covariates_lasso_imputed(data, "y", "x1", c(1, 0.1)), "at least two")
  expect_error(screen_covariates_lasso_imputed(data, "y", c("x1", "y"), c(1, 0.1)), "cannot also")
  expect_error(screen_covariates_lasso_imputed(data, "y", c("x1", "x1"), c(1, 0.1)), "unique")
  expect_error(screen_covariates_lasso_imputed(data, "missing", c("x1", "x2"), c(1, 0.1)), "response")
  for (column in list(factor(rep(c("A", "B"), 9)), rep(TRUE, 18), I(matrix(1:36, 18)))) {
    changed <- data
    changed$x1 <- column
    expect_error(fit(changed, lambda = c(1, 0.1)), "real numeric vectors")
  }
  for (variable in c("x1", "y")) {
    changed <- data
    changed[[variable]][1] <- Inf
    expect_error(fit(changed, lambda = c(1, 0.1)), "infinite values")
  }
  data$y[] <- NA_real_
  expect_error(fit(data, lambda = c(1, 0.1)), "three observed-response")
})

test_that("fold integrity and unusable training sets have contextual errors", {
  data <- imputed_lasso_asymmetric()
  fit <- function(data, folds = rep(1:3, each = 3), ...) {
    screen_covariates_lasso_imputed(data, "y", c("x1", "x2"),
      lambda = c(1, 0.1), id = "subject", foldid = folds, ...
    )
  }
  expect_error(fit(data, rep(1:3, 3)), "single fold")
  expect_error(fit(data, rep(1:2, length.out = 9)), "three nonempty folds")
  expect_error(fit(data, 1:3), "per original data row")
  expect_error(fit(data, NULL, nfolds = 4), "exceeds the number")
  changed <- data
  changed$subject[1] <- NA_character_
  expect_error(fit(changed), "nonmissing vector")
  changed <- data
  changed$x1[4:9] <- NA_real_
  expect_error(fit(changed), "Training data excluding fold 1: Variable 'x1' needs at least one observed")
  changed <- data
  changed$y[4:9] <- 1
  expect_error(fit(changed), "Training data excluding fold 1: constant response")
  changed <- data
  changed[4:9, c("x1", "x2")] <- 0
  expect_error(fit(changed), "Training data excluding fold 1: no varying covariates")
})

test_that("a truncated backend path cannot be silently used for tuning", {
  original <- glmnet::glmnet
  local_mocked_bindings(
    glmnet = function(...) {
      fit <- original(...)
      fit$lambda <- head(fit$lambda, -1)
      fit
    }, .package = "glmnet"
  )
  expect_error(screen_covariates_lasso_imputed(
    imputed_lasso_orthogonal(), "y", c("x1", "x2"), c(2, 1, 0.5),
    foldid = rep(1:3, each = 6)
  ), "complete finite path")
})
