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

## Fixed-fold selection reference

The [model-selection reference tests](https://github.com/DiogoRibeiro7/PharmaStatsR/blob/main/tests/testthat/test-ai-model-reference.R)
use 24 fixed binary observations and three explicit hold-out folds: rows 1--8,
9--16, and 17--24. Their complements are supplied through
\`trainControl(index = ..., indexOut = ...)\`, so the resampling population does
not depend on a random fold generator.

The candidate set is deliberately small: \`glm\` and \`lda\`. The expected
selection is reconstructed **outside caret** for every fold:

- the logistic candidate is fitted directly with \`stats::glm(...,
  family = binomial())\` and classified at probability 0.5;
- the LDA candidate is reconstructed in base R from class means, empirical
  class priors, and the pooled within-class covariance. For class \(k\), the
  discriminant is

\[
\delta_k(x)=x^\top\Sigma^{-1}\mu_k
-\frac{1}{2}\mu_k^\top\Sigma^{-1}\mu_k+\log\pi_k.
\]

The fixed hold-out accuracies are

| Candidate | Fold 1 | Fold 2 | Fold 3 | Mean Accuracy |
| --- | ---: | ---: | ---: | ---: |
| GLM | 0.875 | 0.750 | 0.625 | 0.750 |
| LDA | 0.500 | 0.750 | 0.500 | 7/12 |

Thus the independently reconstructed winner is GLM. The test then checks that
caret's saved fold predictions agree with those direct predictions, that the
candidate summary accuracies equal the reconstructed means, and that
\`pharma_ai_model_select()\` returns the GLM fit as \`best_model\`.

This is stronger than checking only \`fit$results\`, but it is not an
independent validation of all caret model engines. The GLM component still uses
R's statistical GLM implementation; the LDA discriminant is reconstructed
explicitly from the training folds.

Additional contract tests verify that a numeric binary response becomes a
factor for Accuracy, a failed candidate is omitted while successful candidates
remain eligible, exact metric ties keep the first requested candidate because
the wrapper uses \`which.max()\`, and \`explain = TRUE\` returns a named
\`varImp.train\` result for a successful GLM candidate.

These fixed folds document the wrapper's **selection mechanics**, not external
generalization performance. The same data are used to define and compare
candidate procedures through cross-validation; a final independent test set or
nested resampling would be needed for an unbiased post-selection performance
estimate. The reference does not validate the default four-model search,
hyperparameter grids, probability calibration, fairness, causal interpretation,
or every optional model engine.


## Dependency and interpretation

- `caret` is an optional dependency. Install it with `install.packages("caret")` before using this helper. Some candidate algorithms also require their own model-engine packages; [caret's package metadata](https://CRAN.R-project.org/package=caret) lists many of these as suggested dependencies. The default `"glm"`, `"rf"`, `"svmLinear"`, and `"gbm"` candidates may therefore have different availability in a minimal installation.
- To request only the caret GLM workflow, set `models = "glm"` explicitly. The `best_model` is still a caret `train` object, with resampling, rather than a bare `stats::glm` fit. Missing `caret` returns an error regardless of the requested candidate.
- Cross-validation scores estimate performance under the specified folds and metric. They are not a performance estimate from an independent test set after model selection. Examine warnings and `names(fit$all_models)` to see which candidates actually ran; choose resampling, tuning, and an external evaluation appropriate to the analysis.

Earlier calls without `caret` returned a binomial GLM even when other algorithms or a different outcome were requested. Install `caret` and rerun the stated search, then compare any earlier results with the intended model. See [limitations](limitations.md) and the [method inventory](method-inventory.md) for review status.

## R help

Full arguments and return values: [`pharma_ai_model_select()`](https://github.com/DiogoRibeiro7/PharmaStatsR/blob/main/man/pharma_ai_model_select.Rd). In an installed package, run `help("pharma_ai_model_select", package = "PharmaStatsR")`.
