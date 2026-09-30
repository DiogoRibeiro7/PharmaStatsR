test_that("missing caret never substitutes a binomial GLM", {
  testthat::local_mocked_bindings(
    .pharma_caret_available = function() FALSE
  )

  expect_error(
    pharma_ai_model_select(
      outcome ~ treatment, data = pharma_sample,
      models = c("rf", "glm"), metric = "Accuracy", explain = TRUE
    ),
    "install.packages\\('caret'\\).*No model was fitted"
  )
})

test_that("an explicit glm candidate still uses caret resampling", {
  skip_if_not_installed("caret")
  set.seed(42)
  res <- pharma_ai_model_select(
    outcome ~ treatment, data = pharma_sample,
    models = "glm", metric = "Accuracy",
    trControl = caret::trainControl(method = "cv", number = 3)
  )

  expect_s3_class(res$best_model, "train")
  expect_identical(res$best_model$method, "glm")
  expect_identical(names(res$all_models), "glm")
  expect_identical(res$best_model, res$all_models[["glm"]])
  expect_null(res$variable_importance)
})
