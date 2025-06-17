# PharmaTestSuite Roadmap (Statistical Focus)

## ✅ Short Term (0–3 months)
- [x] Package skeleton with roxygen docs, examples and NEWS.md.  
- [x] Basic wrappers: t-test, chi-square, one-way ANOVA, logistic regression.  
- [x] Non-parametric tests: Wilcoxon rank-sum, Kruskal–Wallis.  
- [x] Power & sample-size calculators for t, ANOVA, survival.  
- [x] Multiple comparisons corrections: Bonferroni, Holm, Benjamini–Hochberg FDR.  
- [x] Bootstrap CIs and permutation tests for arbitrary statistics.  
- [x] Unit tests (`testthat`) covering ≥ 90 % of exported functions.  
- [x] GitHub Actions: R CMD check, code coverage, linting.

## ⬜ Medium Term (3–6 months)
- [ ] **Survival analysis**  
  - [x] Kaplan–Meier with log-rank tests  
  - Cox proportional hazards (time-varying covariates)  
  - [x] Parametric survival (Weibull, exponential, Gompertz)
  - Competing-risks and landmark analysis  
- [ ] **Mixed & repeated measures**  
  - Linear mixed models (`lme4`)  
  - Generalized estimating equations (GEE)  
  - Repeated-measures ANOVA / MANOVA  
- [ ] **Bayesian statistics**  
  - MCMC via `brms` / `rstanarm`  
  - Posterior summaries, credible intervals, posterior predictive checks  
- [ ] **Meta-analysis**  
  - Fixed- and random-effects models (`metafor`)  
  - Forest plots, funnel plots, meta-regression  
- [ ] **Dose–response & PK/PD**  
  - Emax, sigmoid Emax models  
  - Nonlinear regression (`nls`), nlme  
- [ ] **Adaptive & sequential designs**  
  - Group-sequential boundaries (O’Brien–Fleming, Pocock)  
  - Sample-size re-estimation  
  - Bayesian adaptive stopping rules  
- [ ] **Design of experiments**  
  - Factorial ANOVA, response-surface methods  
  - Crossover and Latin-square analyses  
- [ ] **Missing data & imputation**  
  - Multiple imputation (`mice`)  
  - Sensitivity analyses  

## ⬜ Long Term (6–12 months)
- [ ] **Trial simulation engine**  
  - Simulate end-to-end trials under various randomization, dropout, event scenarios  
- [ ] **High-performance & parallel**  
  - Parallel backends (`future`), GPU-accelerated bootstrap/simulation  
- [ ] **Advanced resampling**  
  - Wild bootstrap, block bootstrap for clustered data  
  - Permutation-based F-tests in complex designs  
- [ ] **Non-inferiority & equivalence testing**  
  - Two one-sided tests (TOST) for bioequivalence  
  - Rate/risk difference and ratio metrics  
- [ ] **Joint & multistate models**  
  - Joint longitudinal‐survival models  
  - Multistate illness-death processes  
- [ ] **Model diagnostics & QC**  
  - Residual analysis, influence measures, control charts  
  - Automated flagging of outliers & data errors  
- [ ] **Statistical reporting**  
  - Auto-generate APA/ICH-style tables of estimates, CIs, p-values  
  - Export to Word/Excel with formatting  

## ⬜ Extended Vision (>12 months)
- [ ] AI-driven model selection and hyperparameter tuning  
- [ ] Automatic statistical analysis plan (SAP) generation  
- [ ] Interactive R Markdown dashboard for exploring results  
- [ ] Plugin API for community-contributed tests and methods  
- [ ] Integration with Python’s `scipy`/`statsmodels` via `reticulate`  
- [ ] Blockchain-backed audit trail of all analyses  
- [ ] Regulatory validation reports (ICH E9(R1) estimands)  
- [ ] Real-time interim monitoring dashboards  
