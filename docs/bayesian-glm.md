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
## Reproducible numerical reference

The [reference test](https://github.com/DiogoRibeiro7/PharmaStatsR/blob/main/tests/testthat/test-bayesian-reference.R)
fits an intercept-only binomial logit to eight events and four non-events.
It specifies `prior_intercept = rstanarm::normal(0, 1, autoscale = FALSE)`,
`algorithm = "sampling"`, two chains of 1,000 iterations each (500 warmup
per chain), one core, and seed 47. There are no slope priors in this
intercept-only design. The likelihood is 12 independent Bernoulli outcomes
with common probability `plogis(alpha)`. The prior is a standard normal
density for the logit intercept.

An independent one-dimensional quadrature integrates
`dnorm(alpha) * plogis(alpha)^8 * (1 - plogis(alpha))^4`.
It gives posterior mean logit about 0.53191, posterior mean event
probability about 0.62234, and central 80% logit quantiles about
-0.13101 and 1.20528. The test compares sampled summaries with these
values using absolute tolerances 0.15 for the mean and 0.3 for the
quantile endpoints, allowing Monte Carlo error over 1,000 retained draws
without fixing a random sequence. It checks that the returned quantile
columns match `prob = 0.8` and the default `prob = 0.95`, and inspects
effective sample size and R-hat before comparing posterior quantities.
The all-Suggests CI job records its installed `rstanarm` and `bayesplot`
versions and those diagnostics in the test log linked from the PR.

For `plotfun = "stat", stat = "mean"`, the predictive plot places the
observed fraction `8/12` at its reference line and displays means from
100 replicated 12-trial datasets. Their average is compared to the
independent posterior predictive mean above with a 0.15 tolerance.
This simple mean statistic is a check of what the plot represents, not
a sensitive model-criticism statistic. A visually plausible plot or
acceptable sampler diagnostics does not validate the chosen likelihood,
prior, exchangeability assumptions, or a clinical analysis.

The [evidence inventory](method-inventory.md) records this narrow
reference for the three exports. Missing-backend guards run on every PR;
the installed sampler and plot run only with `rstanarm` and `bayesplot`
present in the all-Suggests matrix.
