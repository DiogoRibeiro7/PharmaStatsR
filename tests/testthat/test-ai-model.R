test_that("pharma_ai_model_select errors without caret", {
  if (requireNamespace("caret", quietly = TRUE)) {
    res <- pharma_ai_model_select(response ~ treatment, data = pharma_sample,
                                  models = c("glm"), metric = "Accuracy")
    expect_type(res, "list")
    expect_true("best_model" %in% names(res))
  } else {
    expect_error(pharma_ai_model_select(response ~ treatment, pharma_sample),
                 "caret")
  }
})
