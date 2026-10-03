# Method guide

Use the installed R help pages for full argument and return documentation, for example `?pharma_tost`. This guide points to representative functions; it is not a claim that every method has been independently validated.

The [export and evidence inventory](method-inventory.md) records every public symbol, its source and help page, representative test evidence, site coverage, and review priority.

The [core inference reference cases](core-reference-cases.md) give fixed numerical checks and assumptions for six commonly used helpers.

The [reporting and monitoring scope audit](claims-audit.md) compares sensitive helper names with their actual return values and checks.

| Analysis | Representative functions | Backend |
| --- | --- | --- |
| Group comparisons and designs | `pharma_t_test()`, `pharma_tost()`, [`pharma_anova()`](anova.md), [`pharma_factorial_anova()`](factorial-anova.md), [`pharma_repeated_anova()`](repeated-anova.md), [`pharma_crossover_anova()`](crossover.md), [`pharma_latin_square_anova()`](latin-square.md) | Core R dependencies |
| Quadratic response surface | [`pharma_response_surface()`](response-surface.md) | Core R dependencies; two numeric predictors and a full-rank design |
| Global permutation model test | [`pharma_perm_f_test()`](permutation.md) | Core R dependencies; requires exchangeable responses |
| Rates and uncertainty | [`pharma_rate_metrics()`](rates.md), [`pharma_wild_bootstrap()`](wild-bootstrap.md) | Core R dependencies; review interval assumptions |
| Independent-row bootstrap | [`pharma_parallel_bootstrap()`](parallel-bootstrap.md) | `future`, `future.apply` (optional); uses row resampling |
| Cluster bootstrap | [`pharma_block_bootstrap()`](cluster-bootstrap.md) | Core R dependencies; observed clusters sampled with replacement |
| Trial simulation | [`pharma_trial_simulate()`](trial-simulation.md) | Core R dependencies; independent two-arm time-to-event draws |
| Survival | [`pharma_survival_fit()` and `pharma_parametric_survival()`](survival-regression.md), [`pharma_kaplan_meier()`](kaplan-meier.md), [`pharma_landmark_analysis()`](landmark-analysis.md), [`pharma_cox_timevarying()`](cox-timevarying.md), [`pharma_multistate_model()`](multistate.md) | `survival` (required); `mstate` (optional) for transition hazards |
| Competing risks | [`pharma_competing_risks()`](competing-risks.md) | `cmprsk` (optional); proportional subdistribution hazards |
| Local audit log | [`pharma_audit_log()` and `pharma_audit_verify()`](audit-log.md) | `openssl` (optional); keyed CSV chain |
| Model diagnostics | [`pharma_model_diagnostics()`](model-diagnostics.md) | Base R `lm` / `glm`; descriptive screening |
| Longitudinal and correlated outcomes | `pharma_lmm()`, [`pharma_gee()`](gee.md), [`pharma_joint_model()`](joint-model.md) | `lme4`, `geepack`, `JM` (optional) |
| Meta-analysis | [`pharma_meta_analysis()`](meta-analysis.md), [`pharma_network_meta_analysis()`](network-meta-analysis.md) | `metafor`, `netmeta` (optional) |
| Candidate model selection | [`pharma_ai_model_select()`](model-selection.md) | `caret` (optional); selected model engines may need other packages |
| Python t-test bridge | [`pharma_scipy_ttest()`](scipy-bridge.md) | `reticulate` and Python `scipy.stats` (optional) |
| Model estimate table exports | [`pharma_report_table()`](report-exports.md) | `broom` (required); `openxlsx`, `flextable`, and `officer` for files (optional) |
| Missing data and Bayesian workflows | [`pharma_mice_impute()` and `pharma_sensitivity_analysis()`](missing-data.md), `pharma_bayesian_glm()` | `mice`, `rstanarm` (optional) |
| Single-arm Bayesian response threshold | [`pharma_bayes_stopping()`](bayesian-threshold.md) | Core R dependencies; threshold check only |
| Balanced two-arm planning total | [`pharma_sample_reestimate()`](sample-size.md) | Core R dependencies; normal-approximation planning only |
| Planned interim efficacy boundaries | `pharma_group_seq()` | `gsDesign` (required); see [group-sequential designs](sequential.md) |
| Dose response | `pharma_emax()`, `pharma_sigmoid_emax()` | Core R dependencies |

The formula interfaces of `pharma_t_test()` and [`pharma_anova()`](anova.md) reject missing response or group values. Decide whether to exclude or impute those observations before calling either function, and record the resulting analysis population. ANOVA estimates may also depend on group balance and the model specification.

Other exported functions cover design, simulation, reporting, diagnostics, and optional integrations. Browse `help(package = "PharmaStatsR")` for the installed version. Check the [DESCRIPTION file](https://github.com/DiogoRibeiro7/PharmaStatsR/blob/main/DESCRIPTION) for the complete `Imports` and `Suggests` lists. A missing optional backend is reported when its corresponding function is called.

## Before interpreting a result

1. State the estimand and the hypothesis before choosing a function.
2. Verify the data structure, missingness, independence, and model assumptions for that method.
3. Check units, group ordering, uncertainty interval construction, and any multiplicity plan.
4. Reproduce important numerical results with an independent implementation and a relevant reference.
5. Review [limitations and validation](limitations.md) for project-wide constraints.

A passing package check establishes that software examples and tests ran in that environment. It does not certify the statistical method for a particular study.
