# Bayesian GLM and predictive checks

`pharma_bayesian_glm()` delegates fitting to `rstanarm::stan_glm()` and returns
a `stanreg` object. The default is a Gaussian family fitted with MCMC. The
wrapper does not choose a likelihood or prior for the study, check convergence,
or validate predictive adequacy. Pass supported `family`, prior, and sampling
arguments through `...`, and record the choices in the analysis plan.

## Illustrative fit

Install the optional R packages before using this path:

```r
install.packages(c("rstanarm", "bayesplot"))
library(PharmaStatsR)

fit <- pharma_bayesian_glm(
  response ~ treatment,
  data = pharma_sample,
  family = stats::gaussian(),
  chains = 4, iter = 2000, seed = 47
)
posterior_summary <- pharma_posterior_summary(fit, prob = 0.95)
pp_plot <- pharma_pp_check(fit, plotfun = "dens_overlay", seed = 47)
```

`pharma_sample$response` is an illustrative numeric response. Treatment and
dose are perfectly confounded in this fixture, so the fit cannot separate their
effects. The separate `outcome` column is an arbitrary binary label; if you
model a binary outcome, specify a suitable family such as
`family = stats::binomial()` instead of relying on the Gaussian default. No
effect estimated from this dataset has a clinical interpretation. See
[illustrative example data](simulated-data.md).

## Read the returned objects

`pharma_posterior_summary()` returns the backend's `summary.stanreg` matrix.
The `prob` argument selects central posterior quantiles through the backend's
`probs` argument; the wrapper does not validate `prob`. Inspect the reported
Monte Carlo error, effective sample size, and R-hat alongside the interval,
then review model-specific diagnostics and priors. A narrow interval is not
evidence that the likelihood, prior, or sampling run was adequate. See the
[rstanarm summary reference](https://mc-stan.org/rstanarm/reference/summary.stanreg.html).

`pharma_pp_check()` passes the fitted object to `bayesplot::pp_check()`;
`rstanarm` supplies the `stanreg` method. It returns a ggplot comparing observed
data with posterior predictive draws. `plotfun` and `seed` above are forwarded
to that method. A useful plot does not establish calibration or model validity;
choose checks that address the outcome and the intended use. See the
[rstanarm predictive-check reference](https://mc-stan.org/rstanarm/reference/pp_check.stanreg.html).

The [installed R help](https://github.com/DiogoRibeiro7/PharmaStatsR/blob/main/man/pharma_bayesian_glm.Rd)
documents the fitting wrapper, with separate help for
[`pharma_posterior_summary()`](https://github.com/DiogoRibeiro7/PharmaStatsR/blob/main/man/pharma_posterior_summary.Rd)
and [`pharma_pp_check()`](https://github.com/DiogoRibeiro7/PharmaStatsR/blob/main/man/pharma_pp_check.Rd).
The [evidence inventory](method-inventory.md) marks these as candidate methods:
missing-backend errors are tested on every PR, while the installed fit,
summary, and plot are exercised only when `rstanarm` and `bayesplot` are present
in the all-Suggests matrix. Those tests are software checks, not an independent
assessment of Bayesian inference or a clinical validation.
