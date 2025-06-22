# PharmaTestSuite Roadmap (Statistical Focus)

## ✅ Short Term (0–3 months)
- [x] Package skeleton with roxygen docs, examples and NEWS.md.  
- [x] Basic wrappers: t-test, chi-square, one-way ANOVA, logistic regression.  
- [x] Non-parametric tests: Wilcoxon rank-sum, Kruskal–Wallis.  
- [x] Power & sample-size calculators for t, ANOVA, survival.  
- [x] Multiple comparisons corrections: Bonferroni, Holm, Benjamini–Hochberg FDR.
- [x] Bootstrap CIs and permutation tests for arbitrary statistics.
- [x] Created a CITATION file and added dataset disclaimers in the README.
- [x] Unit tests (`testthat`) covering ≥ 90 % of exported functions.
- [x] GitHub Actions: R CMD check, code coverage, linting.

## ⬜ Medium Term (3–6 months)
- [x] **Survival analysis**
  - [x] Kaplan–Meier with log-rank tests
  - [x] Cox proportional hazards (time-varying covariates)
  - [x] Parametric survival (Weibull, exponential, Gompertz)
  - [x] Competing-risks and landmark analysis
- [x] **Mixed & repeated measures**
  - [x] Linear mixed models (`lme4`)
  - [x] Generalized estimating equations (GEE)
  - [x] Repeated-measures ANOVA / MANOVA
- [x] **Bayesian statistics**
  - [x] MCMC via `brms` / `rstanarm`
  - [x] Posterior summaries, credible intervals, posterior predictive checks
- [x] **Meta-analysis**
  - [x] Fixed- and random-effects models (`metafor`)
  - [x] Forest plots, funnel plots, meta-regression
- [x] **Dose–response & PK/PD**
  - [x] Emax, sigmoid Emax models
  - [x] Nonlinear regression (`nls`), nlme
- [x] **Adaptive & sequential designs**
  - [x] Group-sequential boundaries (O’Brien–Fleming, Pocock)
  - [x] Sample-size re-estimation
  - [x] Bayesian adaptive stopping rules
- [x] **Design of experiments**
  - [x] Factorial ANOVA, response-surface methods
  - [x] Crossover and Latin-square analyses
- [x] **Missing data & imputation**
  - [x] Multiple imputation (`mice`)
  - [x] Sensitivity analyses

## ⬜ Long Term (6–12 months)
- [x] **Trial simulation engine**
  - Simulate end-to-end trials under various randomization, dropout, event scenarios
- [x] **High-performance & parallel**
  - Parallel backends (`future`), GPU-accelerated bootstrap/simulation
- [x] **Advanced resampling**
  - Wild bootstrap, block bootstrap for clustered data
  - [x] Permutation-based F-tests in complex designs
  - [x] **Non-inferiority & equivalence testing**
    - Two one-sided tests (TOST) for bioequivalence
    - Rate/risk difference and ratio metrics
- [x] **Joint & multistate models**
  - Joint longitudinal‐survival models  
  - Multistate illness-death processes  
- [x] **Model diagnostics & QC**
  - Residual analysis, influence measures, control charts
  - Automated flagging of outliers & data errors
- [x] **Statistical reporting**  
  - Auto-generate APA/ICH-style tables of estimates, CIs, p-values  
  - Export to Word/Excel with formatting  

## ⬜ Extended Vision (>12 months)
- [ ] AI-driven model selection and hyperparameter tuning  
- [ ] Automatic statistical analysis plan (SAP) generation  
- [ ] Interactive R Markdown dashboard for exploring results  
- [ ] Plugin API for community-contributed tests and methods  
- [x] Integration with Python’s `scipy`/`statsmodels` via `reticulate`  
- [ ] Blockchain-backed audit trail of all analyses  
- [ ] Regulatory validation reports (ICH E9(R1) estimands)  
- [ ] Real-time interim monitoring dashboards  
