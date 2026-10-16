testthat::local_edition(3)

encoded_lasso_data <- function() {
  block <- data.frame(
    x = c(-1, -1, 1, 1, NA, NA), group = rep(c("A", "B"), 3),
    y = c(-5, 1, -1, 5, -3, 3)
  )
  block[rep(seq_len(6), 3), ]
}

encoded_lasso_fit <- function(data = encoded_lasso_data(), method = "mean",
                              covariates = c("x", "group"), ...) {
  screen_covariates_lasso_imputed(data, "y", covariates,
    lambda = c(4, 2, 1, 0.5), method = method, encode = TRUE,
    foldid = rep(1:3, each = 6), k = 2, ...
  )
}

test_that("mixed fold predictions match independent soft-threshold references", {
  data <- encoded_lasso_data()
  x <- rep(c(-1, -1, 1, 1, 0, 0), 3)
  z <- rep(c(-1, 1), 9)
  penalties <- c(4, 2, 1, 0.5)
  # Standardized numeric x has population variance 2/3. The complementary
  # indicators span z; their L1 penalty yields a unique fitted group contrast,
  # although individual indicator coefficients need not be unique.
  expected <- outer(x, pmax(2 - penalties * sqrt(3 / 2), 0)) +
    outer(z, pmax(3 - penalties, 0))
  for (method in c("mean", "median", "knn")) {
    result <- encoded_lasso_fit(method = method)
    expect_equal(unname(result$predictions), expected, tolerance = 1e-6)
    expect_equal(result$cv$mse, c(35 / 3, 20 / 3, 2, 0.5), tolerance = 1e-6)
    expect_identical(result$selected, c("x", "group"))
    expect_identical(result$lambda.min, 0.5)
    expect_identical(result$encoding$columns, c("x", "groupA", "groupB"))
    expect_identical(names(result$fold_encoding), c("1", "2", "3"))
    expect_true(all(result$selected_columns %in% result$encoding$columns))
    expect_true(any(result$selected_columns %in% c("groupA", "groupB")))
    expect_equal(unname(predict_lasso_imputed(result, data, penalties)), expected, tolerance = 1e-6)
    for (fold in 1:3) {
      expect_identical(names(result$fold_encoding[[fold]]$variables), c("x", "group"))
    }
  }
  selected <- screen_covariates_lasso_imputed(data, "y", c("x", "group"),
    lambda = c(4, 2), encode = TRUE, foldid = rep(1:3, each = 6)
  )
  expect_identical(selected$selected, "group")
  expect_false("x" %in% selected$selected_columns)
})

test_that("only training rows determine replacements, encoding and kNN donors", {
  data <- data.frame(
    x = c(1, NA, 2, 3, NA, 9, 8, NA, 20),
    group = rep(c("A", "B", "B"), 3), y = 1:9
  )
  expected <- list(mean = c(10, 31 / 4, 15 / 4), median = c(17 / 2, 5, 5 / 2), knn = c(9, 2, 2))
  for (method in names(expected)) {
    fit <- function(d) {
      screen_covariates_lasso_imputed(d, "y", c("x", "group"),
        lambda = c(1, 0.1), encode = TRUE, method = method, k = 1,
        foldid = rep(1:3, each = 3)
      )
    }
    result <- fit(data)
    for (fold in 1:3) {
      params <- result$fold_imputation[[fold]]
      new <- data.frame(x = NA_real_, group = "B")
      completed <- if (method == "knn") apply_knn_imputation(new, params) else apply_imputation(new, params)
      expect_equal(completed$x, expected[[method]][fold])
      if (method == "knn") {
        expect_identical(params$vars, "x")
        expect_identical(params$predictors, c("x", "group"))
        expect_equal(nrow(params$donor_targets), 6)
      }
    }
    changed <- data
    changed$x[1] <- 10000
    changed$y[1:3] <- c(-100, 100, 0)
    changed$group[1:3] <- c("B", "A", "A")
    perturbed <- fit(changed)
    expect_identical(perturbed$fold_imputation[[1]], result$fold_imputation[[1]])
    expect_identical(perturbed$fold_encoding[[1]], result$fold_encoding[[1]])
  }
})

test_that("character novelty fails within its fold while declared schemas are retained", {
  data <- encoded_lasso_data()
  data$group[1:6] <- "C"
  expect_error(encoded_lasso_fit(data), "Held-out data for fold 1: Unseen levels.*group.*C")
  data$group <- factor(data$group, levels = c("A", "B", "C", "D"))
  result <- encoded_lasso_fit(data)
  expect_identical(result$fold_encoding[[1]]$columns, c("x", "groupA", "groupB", "groupC", "groupD"))
  expect_true(all(is.finite(result$predictions)))
  # An undeclared character level is never learned from held-out rows.
  data$group <- c(rep("B", 6), rep("A", 12))
  expect_error(encoded_lasso_fit(data), "Training data excluding fold 1:.*two factor levels")
  data <- encoded_lasso_data()
  data$group[1] <- NA_character_
  expect_error(encoded_lasso_fit(data), "Held-out data for fold 1:.*categorical values cannot be missing")
  data$group[7] <- NA_character_
  expect_error(encoded_lasso_fit(data), "Training data excluding fold 1:.*categorical values cannot be missing")
})

test_that("saved encoding survives changed contrasts, names, batches and serialization", {
  data <- encoded_lasso_data()
  data$other <- factor(rep(c("low", "low", "high", "high", "low", "high"), 3),
    levels = c("low", "high")
  )
  names(data)[1:2] <- c("dose + amount", "arm value")
  original_options <- options(contrasts = c("contr.treatment", "contr.poly"))
  on.exit(options(original_options), add = TRUE)
  result <- encoded_lasso_fit(data, covariates = c("dose + amount", "arm value", "other"))
  expect_equal(unname(result$encoding$variables$other$coding), matrix(c(0, 1), 2))
  new <- data[1:3, c("other", "arm value", "dose + amount")]
  new[["dose + amount"]][1] <- NA_real_
  predicted <- predict_lasso_imputed(result, new, c(0.5, 2))
  options(contrasts = c("contr.sum", "contr.helmert"))
  new$other <- factor(new$other, levels = c("high", "low", "unused"))
  original <- result
  expect_identical(predict_lasso_imputed(result, new, c(0.5, 2)), predicted)
  expect_identical(predict_lasso_imputed(result, new[1, , drop = FALSE], c(0.5, 2)), predicted[1, , drop = FALSE])
  new[["dose + amount"]][2] <- 1e6
  expect_identical(predict_lasso_imputed(result, new, c(0.5, 2))[1, , drop = FALSE], predicted[1, , drop = FALSE])
  expect_equal(dim(predict_lasso_imputed(result, new[FALSE, ], c(0.5, 2))), c(0L, 2L))
  expect_identical(result, original)
  path <- tempfile(fileext = ".rds")
  on.exit(unlink(path), add = TRUE)
  saveRDS(result, path)
  restored <- readRDS(path)
  local_mocked_bindings(
    fit_encoding = function(...) stop("Unexpected encoding fit"),
    fit_imputation = function(...) stop("Unexpected imputation fit"), .package = "PharmaStatsR"
  )
  expect_identical(predict_lasso_imputed(restored, new), predict_lasso_imputed(result, new))
})

test_that("categorical-only designs and logical/ordered candidates have explicit schemas", {
  data <- encoded_lasso_data()
  data$y <- ifelse(data$group == "A", -3, 3)
  result <- encoded_lasso_fit(data, covariates = "group")
  expect_equal(nrow(result$imputation), 0)
  expect_identical(result$selected, "group")
  expect_equal(result$cv$mse, c(9, 4, 1, 0.25), tolerance = 1e-6)
  expect_equal(as.vector(predict_lasso_imputed(result, data.frame(group = c("B", "A")))), c(2.5, -2.5), tolerance = 1e-6)
  expect_error(encoded_lasso_fit(data, method = "knn", covariates = "group"), "at least one numeric candidate")
  data <- encoded_lasso_data()
  data$group <- data$group == "B"
  logical_fit <- encoded_lasso_fit(data)
  expect_identical(logical_fit$encoding$variables$group$kind, "logical")
  expect_equal(logical_fit$cv$mse, c(35 / 3, 20 / 3, 2, 0.5), tolerance = 1e-6)
  data$group <- ordered(ifelse(data$group, "B", "A"), levels = c("A", "B"))
  ordered_fit <- encoded_lasso_fit(data)
  expect_true(all(is.finite(predict_lasso_imputed(ordered_fit, data))))
})

test_that("subject folds, response exclusions and numeric defaults remain intact", {
  data <- encoded_lasso_data()
  data$subject <- rep(c("a", "b", "c"), each = 6)
  excluded <- data[1, ]
  excluded$y <- NA_real_
  excluded$x <- Inf
  excluded$group <- "never used"
  excluded$subject <- NA_character_
  with_missing <- rbind(data, excluded)
  result <- screen_covariates_lasso_imputed(with_missing, "y", c("x", "group"),
    c(4, 2, 1, 0.5),
    encode = TRUE, id = "subject", foldid = c(rep(c(10, 20, 30), each = 6), 99)
  )
  expect_true(all(is.na(result$predictions[19, ])))
  expect_true(is.na(result$foldid[19]))
  expect_identical(result$foldid[1:18], rep(1:3, each = 6))
  expect_equal(result$cv$mse, c(35 / 3, 20 / 3, 2, 0.5), tolerance = 1e-6)
  expect_identical(rownames(result$encoding$variables$group$coding), c("A", "B"))
  expect_error(screen_covariates_lasso_imputed(data, "y", c("x", "group"),
    c(1, 0.5),
    encode = TRUE, id = "subject", foldid = rep(1:3, 6)
  ), "single fold")
  data$group <- ifelse(data$group == "A", -1, 1)
  numeric_fit <- function(...) {
    screen_covariates_lasso_imputed(data, "y", c("x", "group"),
      c(4, 2, 1, 0.5),
      foldid = rep(1:3, each = 6), ...
    )
  }
  expect_identical(numeric_fit(), numeric_fit(encode = FALSE))
  expect_false("encoding" %in% names(numeric_fit()))
  expect_equal(numeric_fit(encode = TRUE)$predictions, numeric_fit()$predictions)
})

test_that("invalid encoded inputs and inconsistent saved recipes fail clearly", {
  data <- encoded_lasso_data()
  for (value in list(NA, 1, "yes", logical(), c(TRUE, FALSE), matrix(TRUE))) {
    expect_error(screen_covariates_lasso_imputed(data, "y", c("x", "group"), c(1, 0.5), encode = value), "encode.*TRUE or FALSE")
  }
  expect_error(encoded_lasso_fit(covariates = character()), "at least one candidate")
  expect_error(encoded_lasso_fit(covariates = "x"), "at least two columns")
  expect_error(encoded_lasso_fit(method = "knn", weights = c(group = 0)), "another positive-weight predictor")
  data$groupA <- data$x
  expect_error(encoded_lasso_fit(data, covariates = c("groupA", "group")), "ambiguous output column")
  result <- encoded_lasso_fit()
  new <- data.frame(group = "A", x = NA_real_)
  changed <- new
  changed$group <- "novel"
  expect_error(predict_lasso_imputed(result, changed), "Prediction data: Unseen levels.*group.*novel")
  changed$group <- NA_character_
  expect_error(predict_lasso_imputed(result, changed), "Prediction data:.*categorical values cannot be missing")
  expect_error(predict_lasso_imputed(result, new["x"]), "Prediction data:.*not found")
  changed <- result
  changed$encoding <- NULL
  expect_error(predict_lasso_imputed(changed, new), "replacement table")
  changed <- result
  changed$encoding$version <- 99L
  expect_error(predict_lasso_imputed(changed, new), "Invalid encoding recipe")
  changed <- result
  changed$covariates <- rev(changed$covariates)
  expect_error(predict_lasso_imputed(changed, new), "encoding disagrees")
  changed <- result
  rownames(changed$fit$beta) <- rev(rownames(changed$fit$beta))
  expect_error(predict_lasso_imputed(changed, new), "model coefficients")
})
