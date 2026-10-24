# Limitations and validation

PharmaStatsR is under development and not on CRAN. The included datasets are small illustrative examples, not evidence about real treatments or patients. Do not use them for clinical decisions or include patient data in issues.

The experimental [weight-allometric fitter](allometric-nonlinear.md) supports
one prespecified oral model with fixed weight exponents, independent random
effects on absorption and clearance, and additive residual error. It does not
estimate weight exponents or select covariates. Constant subject weights and
explicit bolus doses are required; infusion, implicit repeated doses,
steady-state, censoring, and multiple endpoints are rejected. Analytic
concentration references test the structural model; a successful SAEM run does
not establish identifiability, a global optimum, or calibrated uncertainty.
Optional starting values enable sensitivity checks for this fixed model; they
do not fix parameters, change bounds, or implement automatic multi-start selection.
The saved-model prediction helper uses zero subject effects and explicit dose
history supplied in each call. These are typical-subject point predictions,
not marginal population means, fitted individual predictions, or intervals.
Missing historical doses cannot be inferred from the provided schedule.
The [allometric response simulator](allometric-simulation.md) draws fresh
subject effects and additive residual noise using fixed fitted variances.
It does not sample parameter uncertainty or model censoring, dropout, or
missingness. Negative simulated responses are retained under the additive
error model; select observation rows from data and simulations before plotting.

## What the checks actually do

| Helper | Implemented behavior | Limit |
| --- | --- | --- |
| `pharma_column_report()` / `pharma_validation_report()` | Check required column names and return an estimand label, row count, required names, and `columns_present = TRUE` after success. | The label is recorded, not assessed. The report does not establish ICH E9(R1) compliance, estimand quality, or data integrity. |
| `pharma_check_columns()` / `check_ich_columns()` | Check the presence of required column names. | Column presence says nothing about their meaning, completeness, or provenance. |
| `pharma_report_table()` | Select five estimate, interval, and p-value columns from `broom::tidy()`; optionally write an Excel or Word file. | Does not format to an APA or ICH standard or validate the model. The tidy output must contain all selected columns. |
| `pharma_generate_sap()` | Return or write Markdown placeholders for a plan; invalid section names and content fail before writing. | Does not complete or approve a study-specific SAP; every relevant section needs study-specific content and independent review. |
| `pharma_dashboard()` / `pharma_interim_dashboard()` | Open bundled example dashboards or return their R Markdown paths. The interim example draws random enrollment counts when rendered. | No live study feed, interim inference, or monitoring decision. |
| `pharma_audit_log()` / `pharma_audit_verify()` | Writes and verifies a local HMAC chained CSV log using a caller supplied key; see [audit log integrity](audit-log.md). | Verification detects edited records in the remaining chain but cannot detect deletion of its final records. No access control, secure key storage, concurrent-write protection, or validated audit system is provided. |
| `pharma_anova()` | Fits an ordinary one-way ANOVA for a categorical group; see [one-way ANOVA](anova.md). | Tests equality of means under independent errors and a common within-group variance. Numeric codes need explicit factor conversion; it does not fit adjusted, repeated-measures, or factorial designs. |
| `pharma_logistic_regression()` | Fits a binomial logit GLM via `stats::glm()`; see [logistic regression](logistic-regression.md). | Outcome coding and model assumptions require review. The bundled binary label has no clinical event definition and is confounded with dose through treatment; a class/family smoke test does not assess calibration or separation. |
| `pharma_factorial_anova()` | Fits two crossed categorical main effects and their interaction after checking balanced replication (at least two observations per cell); see [balanced two-factor ANOVA](factorial-anova.md). | The ordinary F tests rely on independent errors, a common within-cell variance, and a suitable residual distribution. It does not support unbalanced designs, covariates, or repeated measures; `pharma_sample` is confounded and is not a factorial example. |
| `pharma_repeated_anova()` | Fits two complete, factor-coded conditions per subject with an explicit subject error stratum; see [paired ANOVA](repeated-anova.md). | The F test relies on independent subjects and suitable paired differences. Incomplete pairs, numeric IDs, covariates, and more than two conditions are unsupported; recheck earlier numeric-ID fits. |
| `pharma_response_surface()` | Fits a full-rank two-predictor quadratic with linear, squared, and interaction terms; see [response surface](response-surface.md). | Requires at least seven finite observations and an estimable six-column design. Ordinary linear-model assumptions apply; without replicated design points, residual error cannot be separated from lack of fit. The old same-dose example is singular. |
| `pharma_meta_analysis()` | Delegates FE or REML estimation to `metafor::rma()`; see [meta-analysis model choice](meta-analysis.md). | A failed random-effects fit returns its error; FE requires an explicit method choice. The wrapper does not assess the comparability of effect sizes, independence of studies, or suitability of the heterogeneity model. |
| `pharma_ai_model_select()` | Selects the highest-scoring successful `caret` fit; see [candidate model selection](model-selection.md). | Missing `caret` errors. Other model engines can fail individually and are omitted with warnings. The winning resampling score is not an independent test-set assessment or evidence that the model is suitable for a clinical analysis. |
| `pharma_bayesian_glm()` / `pharma_posterior_summary()` / `pharma_pp_check()` | Delegate a model fit, posterior summary, and predictive plot to `rstanarm` and `bayesplot`; see [Bayesian GLM and predictive checks](bayesian-glm.md). | The family, priors, convergence, and predictive behavior require review for each analysis. The summary and plot do not validate the model; the installed path is exercised only in the all-Suggests matrix. |
| `pharma_crossover_anova()` | Fits an additive fixed-subject ANOVA after checking complete two-period AB/BA allocations; see [crossover ANOVA](crossover.md). | Requires both treatments per subject and equal sequence counts. It does not separately estimate carryover or sequence effects, establish bioequivalence, or handle incomplete subjects. |
| `pharma_latin_square_anova()` | Fits an additive ANOVA after checking a complete Latin square with categorical treatment and block terms; see [Latin square ANOVA](latin-square.md). | One unreplicated square does not separately estimate interactions; inference also relies on independent errors and a suitable error distribution. Numeric codes require explicit factor conversion. |
| `pharma_perm_f_test()` | Compares the full linear model with an intercept-only or zero-mean model using unrestricted response permutations; see [global permutation F-test](permutation.md). | Requires exchangeable observations under the global null; it does not test individual terms while adjusting for other predictors. |
| `pharma_parallel_bootstrap()` | Resamples independent rows with replacement, using reproducible future RNG streams; see [row bootstrap](parallel-bootstrap.md). | Does not preserve clustered, repeated, or time-ordered dependence; returns statistics, not calibrated inference. |
| `pharma_block_bootstrap()` | Resamples whole observed clusters with replacement and calls a supplied statistic; see [cluster bootstrap](cluster-bootstrap.md). | The statistic must suit the sampling design. Repeated source clusters need distinct `resample_id` values for grouped downstream fits; the helper does not return calibrated inference. |
| `pharma_wild_bootstrap()` | Returns fixed-design linear-model coefficient draws using independent Rademacher signs on unscaled residuals; see [wild bootstrap](wild-bootstrap.md). | Does not test a null or return calibrated intervals; observation-level signs do not account for clustered or repeated observations, and high leverage can affect accuracy. |
| `pharma_kaplan_meier()` | Fits unweighted right-censored Kaplan–Meier curves and optionally a standard log-rank comparison on the same selected rows; see [Kaplan–Meier and log-rank](kaplan-meier.md). | Assumes censoring is independent of event time within groups. The comparison is unadjusted and does not quantify a treatment effect or account for clustered records. |
| `pharma_landmark_analysis()` | Fits a Cox model in a selected risk set strictly beyond a fixed landmark, shifting observed times to zero; see [landmark Cox analysis](landmark-analysis.md). | Conditional on surviving and remaining observed to the landmark. It does not account for earlier outcomes, establish independent censoring, or remove selection bias from time-dependent exposure. |
| `pharma_cox_timevarying()` | Fits a Cox model on selected, complete counting-process intervals; see [time-varying Cox analysis](cox-timevarying.md). | Valid intervals and complete model variables do not prove that within-subject intervals are ordered, nonoverlapping, or measured with correctly aligned covariates. |
| `pharma_survival_fit()` / `pharma_parametric_survival()` | Delegate to `survival::coxph()` and `survival::survreg()`; see [survival regression](survival-regression.md). | The backend may omit rows with missing model variables. Cox and Weibull regression coefficients have different interpretations; neither fit establishes proportional hazards, an adequate event-time distribution, or independent censoring. |
| `pharma_gee()` | Fits a marginal mean model for clustered observations through `geepack`; see [GEE models](gee.md). | Requires complete model and cluster identifiers and contiguous rows per cluster. Working correlation and standard errors need study-specific review; it does not make clusters independent. |
| `pharma_lmm()` | Delegates a linear mixed model to `lme4::lmer()`; see [linear mixed model](linear-mixed-model.md). | Checks only the data-frame type and formula variable names before fitting. The random-effects structure, missing rows, singularity and convergence, residual assumptions, and independence of subjects need separate review. |
| `pharma_competing_risks()` | Fits a Fine–Gray subdistribution hazards model from numeric event codes and a model matrix; see [competing risks](competing-risks.md). | Estimates the subdistribution hazard for one selected cause under the model and censoring assumptions; it does not estimate a cause-specific hazard or address missing model values. |
| `pharma_model_diagnostics()` | Reports residuals, standardized residuals, Cook's distance and leverage for a univariate `lm` or `glm`; see [model diagnostics](model-diagnostics.md). | Flags use screening cutoffs, not hypothesis tests or proof of data errors. NA diagnostics for omitted rows remain NA; influential points and model assumptions require separate review. |
| `pharma_emax()` / `pharma_sigmoid_emax()` / `pharma_emax_nlme()` | Fit pooled standard or sigmoid Emax curves, or a subject-specific baseline model; see [Emax dose-response curves](dose-response.md). | Starting values and parameter domains are not validated. Pooled fits ignore repeated-subject dependence, and the mixed helper can return an object with a nonconvergence warning at the iteration limit; class-level smoke tests do not establish parameter recovery. |
| `pharma_trial_simulate()` | Generates two-arm event, dropout, and administrative censoring times; see [trial simulation](trial-simulation.md). | Random assignment does not guarantee balance; event and dropout draws are independent, and simulated data do not establish operating characteristics or clinical validity. |
| `pharma_bayes_stopping()` | Computes a beta-binomial posterior probability that one response rate exceeds a fixed benchmark and checks it against a cutoff. See [single-arm posterior threshold](bayesian-threshold.md). | It does not compare arms or calibrate an interim stopping rule's operating characteristics. |
| `pharma_sample_reestimate()` | Calculates a balanced two-arm normal-approximation planning total from a mean difference and within-arm variance; see [sample size planning](sample-size.md). | It does not compute interim conditional power or control the error rate of a data-dependent sample-size change. |
| `pharma_rate_metrics()` | Computes an unadjusted risk difference with a Newcombe interval and an unadjusted risk ratio with a half-count adjusted log interval. See [event-rate comparisons](rates.md). | The ratio interval is approximate and can have poor coverage in small or extreme samples; zero-event ratio point estimates can be undefined or infinite. The function does not adjust for confounding or repeated outcomes. |

The `pharma_validation_report()` and `check_ich_columns()` names are kept for compatibility. New code can use `pharma_column_report()` and `pharma_check_columns()` to make the scope clear. Since the report previously returned a misleading `compliant = TRUE` field, callers that inspected `$compliant` must now inspect `$columns_present` for the **column-presence check only**. The [reporting and monitoring scope audit](claims-audit.md) compares these helpers and the dashboard, SAP, and table helpers with their actual behavior.

The [ICH E9(R1) guideline](https://database.ich.org/sites/default/files/E9-R1_Step4_Guideline_2019_1203.pdf) describes an estimand through the treatment conditions, population, variable, handling of intercurrent events, and population-level summary. A few column names cannot establish those attributes. Names and historical descriptions in this package can imply broader regulatory coverage than the implementation provides. Examine the function source and independently verify calculations before using outputs for a study. See the [security policy](https://github.com/DiogoRibeiro7/PharmaStatsR/blob/main/SECURITY.md) for private vulnerability reporting.

## Consolidated covariate workflows

The [covariate guide](covariate-migration.md#statistical-limits) documents the
18 migrated functions. Single-value imputation does not quantify imputation
uncertainty. AIC/BIC/LASSO screening uses ordinary Gaussian models; grouped
folds alone do not refit preprocessing within each training fold. The linear mixed
model has a fixed random-intercept specification. Its later
[literal-name repair and prediction](covariate-mixed-model.md) preserve that
model: summaries retain backend labels, original-name prediction uses the saved
map, and unknown subjects return `NA` at level 1. No prediction intervals or
new subject effects are estimated. `plot_vpc()` is a descriptive
binned summary, not a simulation-based predictive check. The separate
[`plot_simulated_vpc()`](simulated-vpc.md) summarizes supplied response replicates
with percentile bands. It does not generate simulations, model censoring, perform
prediction correction, or test model adequacy; the supplied simulation design
determines dependence and parameter uncertainty. The later
[`simulate_covariate_model()`](covariate-simulation.md) generates Gaussian
random-intercept replications with fresh subject effects and residuals, holding
fitted coefficients and variances fixed. It does not condition on fitted subject
effects or sample parameter uncertainty, and rejects other random/residual
structures. The original `fit_nlmixr_model()` SAEM
helper is an example-only fixed model and warns that supplied covariates are
ignored. These boundaries are preserved by the consolidation.

The [covariate report](covariate-reports.md) displays the native `nlme`
fixed-effects table with six significant digits and bounded small p-values.
Its inference retains backend defaults; random/residual variance rows,
post-selection adjustments and confidence intervals are absent. Diagnostics
still require native predictor names and `DV`/`Time`; a report is not a model
validation or a substitute for the fitted object's full-precision results.

The [time-varying reshape helper](timevarying-covariates.md) treats all retained
metadata as part of the row key. It rejects duplicate keys in either direction,
but does not establish subject identity. Round trips can add structural missing
cells and change row order; original time classes and row names are not saved.
It performs no aggregation or interpolation.

The [one-table design helper](fitted-encoding.md#one-table-design-checks) rejects
ambiguous expanded names and non-finite coding for observed covariates while
retaining missing input rows. It does not check unused-category coding or full
rank. Saved encoding checks all declared levels; neither helper establishes
identifiability or chooses contrasts appropriate to a scientific question.

The later [fitted-imputation helpers](fitted-imputation.md) save numeric
mean/median replacements for reuse. Their fit/apply separation enables manual
training-fold preprocessing, but does not automatically refit transformations
inside the original LASSO helper. The separate [numeric fold-imputation
helper](lasso-imputation.md) refits mean/median replacements or nearest-neighbor
donors, followed by standardization, for each
training fold using a prespecified penalty grid. Its tuning MSE needs separate
outer evaluation for performance assessment. The [saved encoding helpers](fitted-encoding.md)
retain training coding and reject unseen observed categories, without adding
interactions or checking rank. [Saved nearest-neighbor models](fitted-knn.md)
retain selected training data and use bounded Gower contributions for numeric
targets. Numeric screening integrates those donors within folds with
`method = "knn"` and stops if any predictor cannot be imputed; it does not
fall back to another imputation method or estimate missing-data uncertainty.
The [saved-result prediction helper](predict-lasso-imputed.md) reuses final
parameters without refitting and returns point predictions at fitted penalties;
it does not add prediction intervals or post-selection inference.
[Opt-in categorical fold encoding](lasso-encoding.md) saves additive recipes and
rejects missing or unknown categories. Factor schemas must be prespecified or
training-derived. Column-wise penalties depend on coding; selecting any encoded
column maps back to a raw variable but is not a grouped test. Redundant indicator
coefficients may be nonunique, and unobserved levels have no estimable effect.

The [diagnostics app](diagnostics-app.md) provides keyboard access and numerical
alternatives. Automated Chromium/axe checks cover its documented synthetic
workflow; they do not establish accessibility conformance, screen-reader
announcements, other browser engines, or large-data usability.

The [BIC covariate screener](bic-screening.md) uses a shared complete-case cohort
and univariate Gaussian comparisons. It requires positive residual degrees of
freedom and finite BIC values; these checks do not validate the large-sample
approximation, remove confounding, account for repeated measures, or provide
multiplicity correction and post-selection inference.

The [stepwise AIC screener](aic-screening.md) follows a greedy forward/backward
path and can stop short of the globally best subset. Its accepted-model guards
reject saturated or non-finite fits; they do not preflight every trial or make
post-selection inference valid. The documented local-minimum reference shows
this limitation even with complete, well-behaved numeric data.

The [complete-case LASSO screener](lasso-screening.md) selects exact nonzero
coefficients at the minimum CV error on a backend-generated path. Its new
analytic references cover balanced orthogonal Gaussian LASSO fixtures, not all
elastic-net or correlated designs. Ridge need not be sparse, and the CV error
used to choose the penalty needs separate outer evaluation for performance
assessment. Literal `(Intercept)` predictors are now distinguished from the
fitted intercept; previously affected selections should be recomputed.

The [covariate diagnostic plots](covariate-diagnostic-plots.md) preserve native
prediction/residual defaults and require one numeric value per source row.
They cannot detect a backend that silently reorders an equal-length vector.
The numerical residual reference covers a balanced random-intercept model,
not every residual covariance structure. The descriptive binned ribbon is
not simulated predictive uncertainty; observed and predicted summaries omit
missing values separately and can refer to different rows.

The [scaling fallback](scaling-reference.md) recovers non-finite direct means
and addresses zero or non-finite direct sample-SD calculations; positive finite estimates still have ordinary floating-
point precision. Input differences already rounded away cannot be recovered.
A rounded stored mean can leave nonzero mean standardized values at extreme
offsets. Truly unrepresentable scales or transformed values still raise errors.

## Validation for a real analysis

Document the planned estimand, population, endpoint, intervention, handling of intercurrent events and missing data, and a suitable method. Compare results against independent software or analytic references and review them in the study context. A green CI check or a successful column-presence report does not replace that work.

The [imputation mean fallback](imputation-reference.md) applies only after a
non-finite direct result. Finite estimates can still lose precision, and input
rounding cannot be undone. Neighbor averaging remains unweighted after donor
selection; numerical stability does not establish a missingness assumption or
quantify missing-data uncertainty.
