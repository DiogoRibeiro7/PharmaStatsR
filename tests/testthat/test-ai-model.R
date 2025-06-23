test_that("pharma_ai_model_select errors without caret", {
  if (requireNamespace("caret", quietly = TRUE)) {
    res <- pharma_ai_model_select(response ~ treatment, data = pharma_sample,
                                  models = c("glm", "rf"), metric = "Accuracy")
    expect_type(res, "list")
    expect_true("best_model" %in% names(res))
    expect_true(length(res$all_models) >= 1)
  } else {
    expect_error(pharma_ai_model_select(response ~ treatment, pharma_sample),
                 "caret")
  }
})
