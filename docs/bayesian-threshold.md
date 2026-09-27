# Single-arm posterior threshold

`pharma_bayes_stopping()` checks a **single binary response rate** against a fixed benchmark. It combines a beta prior with observed response counts. The returned `stop` field reports whether a posterior probability crosses a supplied cutoff; the function does not design a monitoring schedule.

```r
library(PharmaStatsR)

out <- pharma_bayes_stopping(
  prior_alpha = 1, prior_beta = 1,
  successes = 8, trials = 10,
  null_rate = 0.5, threshold = 0.95
)
out$prob  # 0.96728515625
out$stop  # TRUE: the probability is strictly above 0.95
```

## What the calculation means

| Input | Interpretation |
| --- | --- |
| `prior_alpha`, `prior_beta` | Positive shapes of a beta prior for one unknown response probability \(p\). |
| `successes`, `trials` | Whole response count and positive participant count for that same arm. |
| `null_rate` | Fixed benchmark \(p_0\) to exceed; it defaults to 0.5 for existing callers. |
| `threshold` | Posterior cutoff used for the Boolean flag; it defaults to 0.95. |

With prior \(p\sim\mathrm{Beta}(a,b)\), \(s\) responses among \(n\) participants give

\[
p\mid s,n\sim\mathrm{Beta}(a+s,\ b+n-s),\qquad
\texttt{prob}=\Pr(p>p_0\mid s,n).
\]

The result uses the beta upper tail, computed by symmetry to retain small positive probabilities. The `stop` field is `TRUE` exactly when `prob > threshold`; equality returns `FALSE`. It is a comparison result, not a recommendation to end recruitment. Changing the prior or benchmark can materially change it.

## Scope of a stopping rule

The calculation **does not compare two treatment arms**. In particular, `prob` is not the posterior probability that an experimental treatment outperforms a control. A response benchmark based on historical information is still a fixed input, not contemporaneous control data.

Repeated interim looks require a pre-specified monitoring schedule and calibration of operating characteristics such as false-positive decisions and power. A cutoff of 0.95 alone does not establish those properties. [Published single-arm designs](https://pmc.ncbi.nlm.nih.gov/articles/PMC8391240/) calibrate their stopping boundaries for a specified schedule and scenarios. The earlier help page inaccurately called this quantity a probability of positive treatment effect; review past interpretations in that light. See [limitations and validation](limitations.md).
