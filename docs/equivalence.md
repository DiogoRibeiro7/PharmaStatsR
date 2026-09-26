# Two one-sided equivalence tests

`pharma_tost()` tests whether the **first group mean minus the second group mean** is strictly between a prespecified lower and upper bound. It uses a Welch standard error and Welch–Satterthwaite degrees of freedom, so it does not require equal group variances.

```r
library(PharmaStatsR)

result <- pharma_tost(
  c(3.1, 3.4, 3.8, 4.0),
  c(3.0, 3.6, 4.2, 4.8),
  low_eqbound = -2,
  high_eqbound = 2,
  alpha = 0.05
)

result$diff       # mean of the first vector minus mean of the second
result$conf.int   # 90% confidence interval when alpha = 0.05
result$p.value    # larger of the two one-sided p-values
result$df         # Welch degrees of freedom
```

Declare equivalence at level `alpha` only when **both** one-sided tests reject (`result$p.value < alpha`). The corresponding `100 × (1 - 2 × alpha)%` confidence interval must fit strictly inside `(low_eqbound, high_eqbound)`. A failure to establish equivalence is not proof of a meaningful difference.

For the formula method, the first **observed factor level** determines the first group. Set factor levels explicitly when direction matters:

```r
data <- pharma_sample
data$treatment <- factor(data$treatment, levels = c("A", "B"))
pharma_tost(
  response ~ treatment, data = data,
  low_eqbound = -2, high_eqbound = 2
)
```

The bounds above are illustrative and have no clinical justification. Select bounds in the response's units before seeing results, ensure independent observations and an appropriate mean comparison, and document missing data and design choices. This helper does not itself establish bioequivalence or regulatory acceptability.
