test_that("pharma_ai_model_select fits with caret or falls back to glm", {
  if (requireNamespace("caret", quietly = TRUE)) {
    res <- pharma_ai_model_select(outcome ~ treatment,
      data = pharma_sample,
      models = c("glm", "rf"), metric = "Accuracy",
      explain = TRUE
    )
    expect_type(res, "list")
    expect_true("best_model" %in% names(res))
    expect_true(length(res$all_models) >= 1)
    expect_true("variable_importance" %in% names(res))
  } else {
    expect_warning(
      res <- pharma_ai_model_select(outcome ~ treatment, pharma_sample),
      "caret"
    )
    expect_s3_class(res$best_model, "glm")
    expect_length(res$all_models, 1)
  }
})
