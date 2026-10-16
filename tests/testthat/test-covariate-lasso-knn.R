testthat::local_edition(3)

knn_lasso_reference <- function() {
  block <- data.frame(
    x1 = c(-1, -1, 1, 1, NA, NA), x2 = c(-1, 1, -1, 1, -1, 1),
    y = c(-2, -2, 2, 2, 0, 0)
  )
  block[rep(seq_len(6), 3), ]
}

knn_lasso_asymmetric <- function() {
  data.frame(
    subject = rep(c("A", "B", "C"), each = 3), y = 1:9,
    x1 = c(1, NA, 2, 3, NA, 9, 8, NA, 20), x2 = rep(c(-1, 1, 0), 3)
  )
}

test_that("fold-specific kNN completion has analytic LASSO coefficients and MSE", {
  data <- knn_lasso_reference()
  original <- data
  lambda <- c(2, 1, 0.5)
  result <- screen_covariates_lasso_imputed(data, "y", c("x1", "x2"),
    lambda,
    method = "knn", k = 2, foldid = rep(1:3, each = 6)
  )
  # For either x2=-1 or x2=1 the first two zero-distance donors have
  # x1=-1 and x1=1. Their mean is zero in every training fold and final fit.
  # Completed x1 has variance 2/3 and is orthogonal to x2 and the intercept.
  slopes <- pmax(2 - lambda * sqrt(3 / 2), 0)
  expect_equal(unname(as.matrix(stats::coef(result$fit))), unname(rbind(rep(0, 3), slopes, rep(0, 3))), tolerance = 1e-7)
  expect_equal(unname(result$predictions), outer(rep(c(-1, -1, 1, 1, 0, 0), 3), slopes), tolerance = 1e-7)
  expect_equal(result$cv$mse, c(8 / 3, 1, 1 / 4), tolerance = 1e-7)
  expect_identical(result$selected, "x1")
  expect_identical(result$lambda.min, 0.5)
  expect_identical(result$method, "knn")
  expect_identical(result$covariates, c("x1", "x2"))
  for (fold in 1:3) {
    held <- result$foldid == fold
    model <- result$fold_imputation[[fold]]
    expect_identical(model$donor_targets, data[!held, c("x1", "x2")])
    expect_equal(apply_knn_imputation(data[held, ], model)$x1, c(-1, -1, 1, 1, 0, 0))
    expect_identical(model$k, 2L)
  }
  expect_equal(apply_knn_imputation(data, result$imputation)$x1, rep(c(-1, -1, 1, 1, 0, 0), 3))
  expect_identical(data, original)
})

test_that("each fold uses its own donors and ranges, with a manual backend reference", {
  data <- knn_lasso_asymmetric()
  result <- screen_covariates_lasso_imputed(data, "y", c("x1", "x2"),
    c(1, 0.1),
    method = "knn", k = 1, id = "subject",
    foldid = rep(c(10, 20, 30), each = 3)
  )
  # Missing x1 has x2=1. Nearest donor x2 is 0; ties follow training order.
  # The first observed x1 at x2=0 is 9, 2, 2 in the three training partitions.
  replacements <- c(9, 2, 2)
  spans <- c(17, 19, 8)
  for (fold in 1:3) {
    held <- result$foldid == fold
    train <- data[!held, ]
    validation <- data[held, ]
    train$x1[is.na(train$x1)] <- replacements[fold]
    validation$x1[is.na(validation$x1)] <- replacements[fold]
    model <- result$fold_imputation[[fold]]
    expect_equal(model$schema$x1$span, spans[fold])
    expect_identical(model$donor_targets, data[!held, c("x1", "x2")])
    expect_equal(apply_knn_imputation(data[!held, ], model)[c("x1", "x2")], train[c("x1", "x2")])
    expect_equal(apply_knn_imputation(data[held, ], model)[c("x1", "x2")], validation[c("x1", "x2")])
    direct <- glmnet::glmnet(as.matrix(train[c("x1", "x2")]), train$y,
      lambda = c(1, 0.1), family = "gaussian", alpha = 1,
      standardize = TRUE, intercept = TRUE
    )
    predicted <- stats::predict(direct, newx = as.matrix(validation[c("x1", "x2")]), s = c(1, 0.1))
    expect_equal(unname(result$predictions[held, ]), unname(predicted))
    expect_false(any(c("y", "subject") %in% c(names(model$donor_targets), names(model$donor_predictors))))
  }
  expect_equal(result$cv$mse, unname(colMeans((result$predictions - data$y)^2)))
  expect_identical(result$imputation$donor_targets, data[c("x1", "x2")])
  expect_equal(apply_knn_imputation(data, result$imputation)$x1[c(2, 5, 8)], rep(2, 3))
})

test_that("held-out outcomes, predictor extremes, and IDs do not leak into donors", {
  fit <- function(data) {
    screen_covariates_lasso_imputed(data, "y", c("x1", "x2"),
      c(1, 0.1),
      method = "knn", k = 1, id = "subject",
      foldid = rep(1:3, each = 3)
    )
  }
  data <- knn_lasso_asymmetric()
  baseline <- fit(data)
  changed <- data
  changed$y[1:3] <- changed$y[1:3] + 100
  changed$subject[1:3] <- "unseen subject"
  result <- fit(changed)
  expect_identical(result$fold_imputation[[1]], baseline$fold_imputation[[1]])
  expect_equal(result$predictions[1:3, ], baseline$predictions[1:3, ])
  expect_false(isTRUE(all.equal(result$cv$mse, baseline$cv$mse)))
  changed <- data
  changed$x1[1] <- 999
  changed$x2[1] <- 1000
  result <- fit(changed)
  expect_identical(result$fold_imputation[[1]], baseline$fold_imputation[[1]])
  expect_equal(result$predictions[2:3, ], baseline$predictions[2:3, ])
  expect_false(isTRUE(all.equal(result$predictions[1, ], baseline$predictions[1, ])))
})

test_that("multiple missing targets use original values with fixed distance weights", {
  block <- data.frame(a = c(0, 100, NA), b = c(10, NA, 30), x = c(0, 5, 10), y = c(0, 10, 20))
  data <- block[rep(1:3, 3), ]
  vars <- c("a", "b", "x")
  result <- screen_covariates_lasso_imputed(data, "y", vars,
    c(1, 0.1),
    method = "knn", k = 1, weights = c(a = 1, b = 1, x = 1),
    foldid = rep(1:3, each = 3)
  )
  # Each incomplete block completes to a=(0,100,100), b=(10,30,30).
  completed <- data
  completed$a[is.na(completed$a)] <- 100
  completed$b[is.na(completed$b)] <- 30
  expect_equal(apply_knn_imputation(data, result$imputation)[vars], completed[vars])
  new <- data.frame(a = NA_real_, b = NA_real_, x = 4)
  # If a=100 were reused in b's distances, b would become 30 instead of 10.
  expect_equal(apply_knn_imputation(new, result$imputation), data.frame(a = 100, b = 10, x = 4))
  weighted <- screen_covariates_lasso_imputed(data, "y", vars,
    c(1, 0.1),
    method = "knn", k = 1, weights = c(a = 0, b = 2, x = 3),
    foldid = rep(1:3, each = 3)
  )
  for (model in c(weighted$fold_imputation, list(weighted$imputation))) {
    expect_identical(model$weights, c(b = 2, x = 3))
    expect_identical(model$predictors, c("b", "x"))
    expect_identical(model$vars, vars)
    expect_identical(model$k, 1L)
  }
})

test_that("row alignment, explicit folds, and final prediction survive serialization", {
  data <- knn_lasso_reference()
  names(data) <- c("dose + amount", "(Intercept)", "outcome")
  vars <- names(data)[1:2]
  data$subject <- rep(1:9, each = 2)
  data$outcome[6] <- NA_real_
  data[[1]][6] <- Inf
  data$subject[6] <- NA_integer_
  rownames(data) <- paste0("case-", seq_len(nrow(data)))
  set.seed(36)
  before <- .Random.seed
  result <- screen_covariates_lasso_imputed(data, "outcome", vars,
    c(2, 1, 0.5),
    method = "knn", k = 2, id = "subject",
    foldid = rep(c(10, 20, 30), each = 6)
  )
  expect_identical(.Random.seed, before)
  expect_identical(result$foldid, c(rep(1L, 5), NA_integer_, rep(2:3, each = 6)))
  expect_true(all(is.na(result$predictions[6, ])))
  expect_true(all(is.finite(result$predictions[-6, ])))
  expect_identical(rownames(result$predictions), rownames(data))
  expect_equal(result$cv$mse, unname(colMeans((result$predictions[-6, ] - data$outcome[-6])^2)))
  expect_identical(result$imputation$donor_targets, data[-6, vars])
  path <- tempfile(fileext = ".rds")
  on.exit(unlink(path), add = TRUE)
  saveRDS(result, path)
  saved <- readRDS(path)
  expect_identical(saved$fold_imputation, result$fold_imputation)
  expect_identical(saved$method, "knn")
  expect_identical(saved$covariates, vars)
  new <- data.frame(a = c(NA, 1), b = c(1, -1))
  names(new) <- vars
  completed <- apply_knn_imputation(new[rev(vars)], saved$imputation)
  expect_equal(completed[[vars[1]]], c(0, 1))
  prediction <- stats::predict(saved$fit, newx = as.matrix(completed[saved$covariates]), s = saved$lambda.min)
  beta <- as.matrix(stats::coef(saved$fit, s = saved$lambda.min))
  expect_equal(as.vector(prediction), as.vector(cbind(1, as.matrix(completed[vars])) %*% beta))
})

test_that("unusable training and held-out neighbors fail with fold and target context", {
  fit <- function(data = knn_lasso_asymmetric(), ...) {
    screen_covariates_lasso_imputed(data, "y", c("x1", "x2"),
      c(1, 0.1),
      method = "knn", foldid = rep(1:3, each = 3), ...
    )
  }
  for (k in list(0, -1, 1.5, NA_real_, Inf, "1", 2^31)) {
    expect_error(fit(k = k), "positive integer")
  }
  for (weights in list(c(y = 1), c(subject = 1), c(x1 = -1), c(x1 = Inf))) {
    expect_error(fit(weights = weights), "Weights refer|weights")
  }
  expect_error(fit(weights = c(x1 = 0)), "Training data excluding fold 1: Target 'x2'.*positive-weight")
  bad <- knn_lasso_asymmetric()
  bad[4, c("x1", "x2")] <- NA_real_
  expect_error(fit(bad), "Training data excluding fold 1: Target 'x1'.*no comparable training donors")
  bad <- knn_lasso_asymmetric()
  bad[1, c("x1", "x2")] <- NA_real_
  expect_error(fit(bad), "Held-out data for fold 1: Target 'x1'.*no comparable training donors")
  bad <- knn_lasso_asymmetric()
  bad$x1[4:9] <- NA_real_
  expect_error(fit(bad), "Training data excluding fold 1: Target 'x1' needs an observed")
  # An entire held-out target column can still be filled using observed x2.
  bad <- knn_lasso_asymmetric()
  bad$x1[1:3] <- NA_real_
  expect_true(all(is.finite(fit(bad, k = 1)$predictions)))
})

test_that("mean and median results expose metadata without changing their defaults", {
  data <- knn_lasso_reference()
  for (method in c("mean", "median")) {
    result <- screen_covariates_lasso_imputed(data, "y", c("x1", "x2"),
      c(2, 1, 0.5),
      method = method, foldid = rep(1:3, each = 6)
    )
    expect_identical(result$method, method)
    expect_identical(result$covariates, c("x1", "x2"))
    expect_s3_class(result$imputation, "data.frame")
    expect_equal(result$cv$mse, c(8 / 3, 1, 1 / 4), tolerance = 1e-7)
  }
  default <- screen_covariates_lasso_imputed(data, "y", c("x1", "x2"),
    c(2, 1, 0.5),
    foldid = rep(1:3, each = 6)
  )
  expect_identical(default$method, "mean")
})
