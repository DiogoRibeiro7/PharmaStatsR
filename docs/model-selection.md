# Candidate model selection

`pharma_ai_model_select()` compares requested `caret::train()` fits by a resampling metric. `caret` must be installed. When it is unavailable, the helper now errors with an installation instruction; it does not replace the requested search with an untuned binomial GLM.

```r
library(PharmaStatsR)

# A single explicit candidate needs caret, but no additional model engine.
fit <- pharma_ai_model_select(
  outcome ~ treatment, data = pharma_sample,
  models = "glm", metric = "Accuracy"
)
fit$best_model
fit$all_models
```

The bundled `outcome` is numeric with two values. For `metric = "Accuracy"`, the helper converts that response to a factor before calling `caret::train()`. With no `trControl`, caret uses five-fold cross-validation. The result is a list containing `best_model`, `all_models` for successfully fitted candidates, and `variable_importance` (`NULL` unless `explain = TRUE`). A candidate that fails during training produces a warning and is omitted; the returned winner is the highest scorer **among successful fits**.

## Dependency and interpretation

- `caret` is an optional dependency. Install it with `install.packages("caret")` before using this helper. Some candidate algorithms also require their own model-engine packages; [caret's package metadata](https://CRAN.R-project.org/package=caret) lists many of these as suggested dependencies. The default `"glm"`, `"rf"`, `"svmLinear"`, and `"gbm"` candidates may therefore have different availability in a minimal installation.
- To request only the caret GLM workflow, set `models = "glm"` explicitly. The `best_model` is still a caret `train` object, with resampling, rather than a bare `stats::glm` fit. Missing `caret` returns an error regardless of the requested candidate.
- Cross-validation scores estimate performance under the specified folds and metric. They are not a performance estimate from an independent test set after model selection. Examine warnings and `names(fit$all_models)` to see which candidates actually ran; choose resampling, tuning, and an external evaluation appropriate to the analysis.

Earlier calls without `caret` returned a binomial GLM even when other algorithms or a different outcome were requested. Install `caret` and rerun the stated search, then compare any earlier results with the intended model. See [limitations](limitations.md) and the [method inventory](method-inventory.md) for review status.
