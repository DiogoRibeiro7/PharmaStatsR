# Fixed-fold model-selection evidence for pharma_ai_model_select().
# Expected fold accuracies are reconstructed outside caret from direct GLM fits
# and base-R LDA discriminants.

caret_selection_reference_data <- function() {
  data.frame(
    outcome = c(
      1, 0, 1, 0, 1, 1, 0, 1,
      0, 1, 1, 0, 0, 0, 0, 0,
      0, 0, 0, 1, 0, 1, 0, 0
    ),
    x1 = c(
      0.7467146432744244, -0.6426091045260228,
      0.70978982863548, -0.5520794855217849,
      -0.7853192312251498, 0.7562322558422047,
      0.3861585439492019, 2.0994023743400736,
      -3.118898256111129, 0.630551185788026,
      -0.2298853239404529, 0.23169637255496894,
      -0.9754168566709864, -0.7340273363690012,
      -0.14722085585710332, -0.4418345294250507,
      -0.407863764373788, -0.7946539842793536,
      -0.2855741695176863, 0.16060062306511505,
      -0.03580286673337402, -0.3346909571359039,
      -0.5511791762288915, -0.012645163699973492
    ),
    x2 = c(
      -0.5489216533913648, -0.7513631133025181,
      0.3515645090743846, 0.8763545386143431,
      -0.4111958684780112, 0.2738242556397848,
      0.9650428351392077, -0.10404668348578062,
      0.47236674510165594, -0.3848194392259383,
      -1.2312973439398303, -1.167720797844092,
      0.9643951963204355, -0.11214575714433653,
      -0.14412396964599147, 0.8623328015555866,
      -1.2756725377320992, 1.0921336164274598,
      0.7075578297392944, 0.04956665161839256,
      -0.3243127150072199, -2.1271243023054875,
      -0.16569907217183483, -1.3756611389626
    )
  )
}

caret_selection_reference_folds <- function() {
  test <- list(
    Fold1 = 1:8,
    Fold2 = 9:16,
    Fold3 = 17:24
  )
  train <- lapply(test, function(idx) setdiff(seq_len(24L), idx))
  list(train = train, test = test)
}

caret_selection_reference_control <- function() {
  folds <- caret_selection_reference_folds()
  caret::trainControl(
    method = "cv",
    number = 3,
    index = folds$train,
    indexOut = folds$test,
    savePredictions = "final",
    returnResamp = "all"
  )
}

caret_selection_reference_lda <- function(train, test) {
  y <- factor(train$outcome)
  x <- as.matrix(train[c("x1", "x2")])
  newx <- as.matrix(test[c("x1", "x2")])
  levels_y <- levels(y)

  means <- do.call(rbind, lapply(levels_y, function(level) {
    colMeans(x[y == level, , drop = FALSE])
  }))
  centered <- do.call(rbind, lapply(seq_along(levels_y), function(i) {
    rows <- x[y == levels_y[i], , drop = FALSE]
    sweep(rows, 2, means[i, ], FUN = "-")
  }))
  pooled <- crossprod(centered) / (nrow(x) - length(levels_y))
  inverse <- solve(pooled)
  priors <- as.numeric(table(y)) / length(y)

  scores <- vapply(seq_along(levels_y), function(i) {
    mu <- means[i, ]
    drop(newx %*% inverse %*% mu -
      0.5 * drop(t(mu) %*% inverse %*% mu) +
      log(priors[i]))
  }, numeric(nrow(newx)))

  factor(levels_y[max.col(scores, ties.method = "first")], levels = levels_y)
}

caret_selection_reference_scores <- function(data) {
  folds <- caret_selection_reference_folds()
  data$outcome <- factor(data$outcome)

  glm_accuracy <- numeric(3L)
  lda_accuracy <- numeric(3L)

  for (i in seq_len(3L)) {
    train <- data[folds$train[[i]], , drop = FALSE]
    test <- data[folds$test[[i]], , drop = FALSE]

    glm_fit <- stats::glm(
      outcome ~ x1 + x2,
      data = train,
      family = stats::binomial()
    )
    glm_prob <- stats::predict(glm_fit, newdata = test, type = "response")
    glm_pred <- factor(
      ifelse(glm_prob >= 0.5, "1", "0"),
      levels = levels(train$outcome)
    )
    lda_pred <- caret_selection_reference_lda(train, test)

    glm_accuracy[i] <- mean(glm_pred == test$outcome)
    lda_accuracy[i] <- mean(lda_pred == test$outcome)
  }

  list(
    glm = glm_accuracy,
    lda = lda_accuracy,
    mean = c(glm = mean(glm_accuracy), lda = mean(lda_accuracy))
  )
}

test_that("fixed folds reconstruct the caret winner outside caret", {
  skip_if_not_installed("caret")

  data <- caret_selection_reference_data()
  expected <- caret_selection_reference_scores(data)

  expect_equal(expected$glm, c(0.875, 0.75, 0.625), tolerance = 1e-12)
  expect_equal(expected$lda, c(0.5, 0.75, 0.5), tolerance = 1e-12)
  expect_equal(expected$mean, c(glm = 0.75, lda = 7 / 12), tolerance = 1e-12)
  expect_gt(expected$mean[["glm"]], expected$mean[["lda"]])

  actual <- pharma_ai_model_select(
    outcome ~ x1 + x2,
    data = data,
    models = c("glm", "lda"),
    metric = "Accuracy",
    trControl = caret_selection_reference_control()
  )

  expect_identical(names(actual$all_models), c("glm", "lda"))
  expect_identical(actual$best_model$method, "glm")
  expect_identical(actual$best_model, actual$all_models[["glm"]])
  expect_true(is.factor(actual$best_model$trainingData$.outcome))

  caret_scores <- vapply(actual$all_models, function(fit) {
    max(fit$results$Accuracy)
  }, numeric(1))
  expect_equal(caret_scores, expected$mean, tolerance = 1e-12)
})

test_that("fixed-fold predictions agree with direct component predictions", {
  skip_if_not_installed("caret")

  data <- caret_selection_reference_data()
  folds <- caret_selection_reference_folds()
  data_factor <- data
  data_factor$outcome <- factor(data_factor$outcome)

  actual <- pharma_ai_model_select(
    outcome ~ x1 + x2,
    data = data,
    models = c("glm", "lda"),
    metric = "Accuracy",
    trControl = caret_selection_reference_control()
  )

  for (i in seq_len(3L)) {
    train <- data_factor[folds$train[[i]], , drop = FALSE]
    test <- data_factor[folds$test[[i]], , drop = FALSE]

    glm_fit <- stats::glm(
      outcome ~ x1 + x2,
      data = train,
      family = stats::binomial()
    )
    glm_pred <- factor(
      ifelse(
        stats::predict(glm_fit, newdata = test, type = "response") >= 0.5,
        "1", "0"
      ),
      levels = levels(train$outcome)
    )
    lda_pred <- caret_selection_reference_lda(train, test)

    resample <- names(folds$test)[i]
    caret_glm <- actual$all_models[["glm"]]$pred
    caret_lda <- actual$all_models[["lda"]]$pred

    expect_identical(
      as.character(caret_glm$pred[caret_glm$Resample == resample]),
      as.character(glm_pred)
    )
    expect_identical(
      as.character(caret_lda$pred[caret_lda$Resample == resample]),
      as.character(lda_pred)
    )
  }
})

test_that("failed candidates are omitted and ties keep request order", {
  skip_if_not_installed("caret")

  data <- caret_selection_reference_data()
  control <- caret_selection_reference_control()

  expect_warning(
    partial <- pharma_ai_model_select(
      outcome ~ x1 + x2,
      data = data,
      models = c("glm", "not_a_caret_model"),
      metric = "Accuracy",
      trControl = control
    ),
    "not_a_caret_model failed to fit"
  )
  expect_identical(names(partial$all_models), "glm")
  expect_identical(partial$best_model$method, "glm")

  tied <- pharma_ai_model_select(
    outcome ~ x1 + x2,
    data = data,
    models = c("glm", "glm"),
    metric = "Accuracy",
    trControl = control
  )
  expect_identical(names(tied$all_models), c("glm", "glm"))
  expect_identical(tied$best_model, tied$all_models[[1L]])
  expect_equal(
    tied$all_models[[1L]]$results$Accuracy,
    tied$all_models[[2L]]$results$Accuracy,
    tolerance = 0
  )
})

test_that("explain returns variable importance for successful candidates", {
  skip_if_not_installed("caret")

  result <- pharma_ai_model_select(
    outcome ~ x1 + x2,
    data = caret_selection_reference_data(),
    models = "glm",
    metric = "Accuracy",
    trControl = caret_selection_reference_control(),
    explain = TRUE
  )

  expect_identical(names(result$variable_importance), "glm")
  expect_s3_class(result$variable_importance[["glm"]], "varImp.train")
  expect_true(all(c("x1", "x2") %in%
    rownames(result$variable_importance[["glm"]]$importance)))
})
