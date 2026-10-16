# Documentation reconciliation

The [export and evidence inventory](method-inventory.md) is the entry point for
source files, help topics, tests, and site pages. Documentation coverage does
not establish statistical validity for every method.

## Current inventory

The [inventory](method-inventory.md) now contains **109 exports**: 103 functions
and six illustrative data objects. The later `fit_imputation()` /
`apply_imputation()` and `fit_encoding()` / `apply_encoding()` pairs have source,
generated help, fixed numerical references, inventory rows, and guides for
[saved imputation](fitted-imputation.md) and [encoding](fitted-encoding.md).
The subsequent `screen_covariates_lasso_imputed()` adds [numeric training-fold
preprocessing](lasso-imputation.md), with independent coefficient/MSE references
and held-out prediction evidence. The later [saved neighbor pair](fitted-knn.md)
adds training-only donors and scales, fixed distance references, and batch-independence tests.
Numeric screening now integrates these donors within folds via `method = "knn"`,
with hand-calculated completions, analytic MSE, and no-donor error evidence.
The [prediction helper](predict-lasso-imputed.md) adds saved-imputer dispatch,
fitted-grid prediction, and schema checks with analytic references.
The package still has seven datasets and six vignettes. The reconciliation below
preserves the earlier consolidation checks for their named source.

## Consolidation baseline: 15 October 2026

At merged commit `65bc1be` on 15 October 2026, `NAMESPACE` contained **101 exports**:
95 functions and six illustrative data objects. Every export has a source
definition, one documented Rd alias, an inventory row, and a support level.
The additional `pharmo_example` dataset has its own help topic and is loaded
with `data()`; it is not another namespace export. The package contains six
vignettes: the original workflow and five covariate guides.

The [merged routine R checks](https://github.com/DiogoRibeiro7/PharmaStatsR/actions/runs/38801594157)
passed, including generated-help consistency. The [five-job matrix](https://github.com/DiogoRibeiro7/PharmaStatsR/actions/runs/38801594182)
passed, including examples, tests, vignette rebuilding, and PDF/HTML manuals
with all Suggested backends. The [documentation build and deployment](https://github.com/DiogoRibeiro7/PharmaStatsR/actions/runs/38801594029)
also passed. That source had two notes, including the lengthy-example timing
finding addressed later. The [release evidence](release-candidate.md) and
[#58](https://github.com/DiogoRibeiro7/PharmaStatsR/issues/58) record later receipts;
each applies only to its named source.

The README, installation and quick-start guides, data inventory, migration
guide, and status pages describe the consolidated package. The retired
pharmoCovR repository is no longer linked as an installation or source endpoint;
its original commit identifier and MIT attribution remain recorded.

The current [API policy](api-support-policy.md) assigns two stable, 88
experimental, 11 example-only, and two deprecation-candidate labels. Use the
current inventory for method evidence: the historical list below predates
the subsequent numerical-reference work and covariate consolidation.

## Historical scope of issue #56

The following snapshot records the original closure of [issue #56](https://github.com/DiogoRibeiro7/PharmaStatsR/issues/56)
through PR #99. Its 72-export counts, evidence gaps, and check notes describe
that earlier source, not the current package.

| Check | Evidence and result |
| --- | --- |
| Public interface | `NAMESPACE` has 72 exports: 66 functions and six illustrative datasets. Each has one Rd alias and a source definition. All 66 functions have a documented return value; the six dataset topics describe format, source, and an example. The no-argument registry listing functions need no `\arguments` section. The S3 t-test and TOST generics share help with their vector/formula method arguments, and the trial simulator documents its two hazard parameters together. |
| Help generation and contracts | The selected-backend PR job regenerates all help from roxygen and fails on a drift diff or a hand-maintained Rd file. Source, help, examples, and site text were reconciled for Bayesian fits and posterior summaries, meta-analysis plotting returns, Emax starting values and convergence, logistic and registry utilities, and configuration restoration in [#93](https://github.com/DiogoRibeiro7/PharmaStatsR/pull/93), [#94](https://github.com/DiogoRibeiro7/PharmaStatsR/pull/94), [#96](https://github.com/DiogoRibeiro7/PharmaStatsR/pull/96), [#97](https://github.com/DiogoRibeiro7/PharmaStatsR/pull/97), and [#99](https://github.com/DiogoRibeiro7/PharmaStatsR/pull/99). |
| Examples and vignette | The [#99 R check](https://github.com/DiogoRibeiro7/PharmaStatsR/actions/runs/37141355869) ran on R release with required dependencies and, separately, selected optional backends plus Python SciPy. Both jobs reported `checking examples ... OK` and `checking re-building of vignette outputs ... OK`. Optional examples guard their backends. The [all-Suggests matrix](https://github.com/DiogoRibeiro7/PharmaStatsR/actions/runs/37120561275) passed on an earlier commit; #58 still needs candidate evidence on one exact commit. |
| Site coverage | Every export in the [inventory](method-inventory.md) links to a guide, reference, or scope page. Focused method pages link their relevant Rd topics, and [the strict MkDocs build](https://github.com/DiogoRibeiro7/PharmaStatsR/actions/runs/37141355899) passed on #99. |

The [inventory test key](method-inventory.md) distinguishes fixed references `[R]`, behavior or backend comparisons `[C]`, smoke checks `[S]`, and optional-backend guards `[G]`. No export is left without a linked representative test or site entry. Smoke-only statistical entries still lack stronger method evidence: logistic regression, the linear mixed model, Bayesian fit/summary/plot, the forest and funnel plots, and the three Emax fits. The SAP template, two dashboards, and greeting also have only smoke-level checks. Documentation completion does not change their evidence level or support classification; [#57](https://github.com/DiogoRibeiro7/PharmaStatsR/issues/57) decides the API policy.

The selected-backend #99 check had one package NOTE because its help-drift step wrote `documentation-drift.patch` to the package root. The workflow now writes that temporary artifact outside the source tree. Its standalone testthat summary also recorded four `mice::mice()` logged-event warnings from test fixtures; they were not R CMD check warnings. Review those fixture warnings alongside the exact-commit matrix and remaining release checks under [#58](https://github.com/DiogoRibeiro7/PharmaStatsR/issues/58).
