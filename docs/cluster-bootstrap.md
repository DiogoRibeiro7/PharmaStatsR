# Cluster bootstrap

`pharma_block_bootstrap()` resamples **whole observed clusters**, with replacement. Each bootstrap data frame contains every row of each selected cluster, and the number of selected clusters equals the number observed in the input. With unequal cluster sizes, replicate row counts can differ. This is a cluster-level cases bootstrap; it does not resample individual rows within a cluster.

```r
library(PharmaStatsR)

trial <- data.frame(
  subject = rep(1:4, each = 2),
  response = c(4, 5, 2, 3, 6, 7, 3, 4)
)
stat <- function(d) mean(d$response)

set.seed(42)
draws <- pharma_block_bootstrap(
  trial, cluster = "subject", statistic = stat,
  R = 500, progress = FALSE
)
unlist(draws)
```

`cluster` may be a single column name or an ID vector with one value per input row, including a character vector. The IDs must be present for every row and identify at least two observed clusters. Unused factor levels are ignored. Missing values in other columns reach your `statistic`; it must decide how to handle them. The callback receives a base data frame. Set a seed to reproduce the cluster draws.

## Repeated copies of a cluster

The original cluster labels remain unchanged in a resample. When a statistic needs each sampled **copy** to be distinguishable (for example, a model that groups by cluster), set `resample_id` to a new column name. Its values run from 1 to the number of selected clusters within each replicate, even when the same source cluster was drawn twice:

```r
count_copies <- function(d) length(unique(d$bootstrap_cluster))
set.seed(42)
pharma_block_bootstrap(
  trial, "subject", count_copies, R = 5, progress = FALSE,
  resample_id = "bootstrap_cluster"
)
```

Pass `resample_id` by name. Any extra arguments before it are passed to `statistic`. Use this new ID in downstream grouped models; grouping by the unchanged source ID can merge repeated copies.

## Independent unequal-cluster reference

The [numerical reference tests](https://github.com/DiogoRibeiro7/PharmaStatsR/blob/main/tests/testthat/test-cluster-bootstrap-reference.R) use the following fixed synthetic ledger. The input interleaves the clusters in row order `C-1, A-1, B-1, C-2, B-2, C-3`; an unrelated column is entirely missing.

| Cluster | Row IDs | Values | Size | Total | Mean |
| --- | --- | --- | --- | --- | --- |
| A | A-1 | 0 | 1 | 0 | 0 |
| B | B-1, B-2 | 2, 4 | 2 | 6 | 3 |
| C | C-1, C-2, C-3 | 6, 8, 10 | 3 | 24 | 8 |

Three clusters are sampled independently and uniformly with replacement. There are `3^3 = 27` equally likely ordered samples. Let `(a, b, c)` count the sampled copies of A, B, and C, with `a + b + c = 3`. Two different statistics are checked:

\[
M_{\mathrm{row}}=\frac{6b+24c}{a+2b+3c},\qquad
M_{\mathrm{copy}}=\frac{3b+8c}{3}.
\]

The first pools all sampled rows. The second weights each sampled cluster copy equally. They are not interchangeable. For example, sampling A, A, C gives `M_row = 24/5` and `M_copy = 8/3`; incorrectly collapsing the repeated A into one source group would instead give an equal-group mean of 4.

### Complete support and exact moments

A count triple has multiplicity `3!/(a! b! c!)`. The following table therefore retains all 27 ordered outcomes rather than assigning equal weight to its ten rows.

| a | b | c | Multiplicity | Sampled rows | Pooled-row mean | Equal-copy mean |
| --- | --- | --- | --- | --- | --- | --- |
| 3 | 0 | 0 | 1 | 3 | 0 | 0 |
| 2 | 1 | 0 | 3 | 4 | 3/2 | 1 |
| 2 | 0 | 1 | 3 | 5 | 24/5 | 8/3 |
| 1 | 2 | 0 | 3 | 5 | 12/5 | 2 |
| 1 | 1 | 1 | 6 | 6 | 5 | 11/3 |
| 1 | 0 | 2 | 3 | 7 | 48/7 | 16/3 |
| 0 | 3 | 0 | 1 | 6 | 3 | 3 |
| 0 | 2 | 1 | 3 | 7 | 36/7 | 14/3 |
| 0 | 1 | 2 | 3 | 8 | 27/4 | 19/3 |
| 0 | 0 | 3 | 1 | 9 | 8 | 8 |

Summing with those multiplicities and dividing by 27 gives

\[
E_*(M)=\begin{pmatrix}2467/540\\11/3\end{pmatrix},\qquad
\operatorname{Cov}_*(M)=
\begin{pmatrix}
14515811/3572100 & 10288/2835\\
10288/2835 & 98/27
\end{pmatrix},
\]

where `M = (M_row, M_copy)` and the star denotes the conditional bootstrap distribution of this fixed dataset. The pooled mean's conditional expectation is approximately `4.56852`, not the original pooled-row mean of 5. This is a finite-support mean-of-ratios calculation, not a claim of bias under every sampling model. The equal-copy expectation is `11/3`, matching the original mean of the three cluster means.

The row counts 3 through 9 have respective multiplicities `(1, 3, 6, 7, 6, 3, 1)` and expectation 6. Full-support covariance uses denominator 27, not the sample-covariance denominator 26. The exact targets were calculated using Python's rational arithmetic and independently checked by explicitly concatenating cluster values for all 27 samples in NumPy. Numeric means and covariance agreed within absolute tolerance `1e-12`.

This base-R calculation reproduces the numerical reference without calling the bootstrap helper:

```r
orders <- as.matrix(expand.grid(first = 1:3, second = 1:3, third = 1:3))
sizes <- c(1, 2, 3)
totals <- c(0, 6, 24)
cluster_means <- c(0, 3, 8)
values <- t(apply(orders, 1, function(ids) {
  c(pooled = sum(totals[ids]) / sum(sizes[ids]),
    equal_copy = sum(cluster_means[ids]) / 3)
}))
center <- colMeans(values)
centered <- sweep(values, 2, center, "-")
center
crossprod(centered) / 27
```

### Seeded execution and callback policies

Production calls still sample; they do not enumerate the support. Under seeds 21 and 149, with one and 31 replicates, the tests replay only the three sampled cluster indices. Expected statistics then come from the fixed size/total ledger, not the callback or a backend resample. Exact checks cover original row IDs, source labels, fresh copy IDs, replicate order, first-replicate consistency, and the post-call random-number state. Test-only seeding restores the previous `.Random.seed` or its absence. The input data must remain unchanged.

The same checks exercise a column name, character IDs, and factor IDs with levels `A, B, C, unused`. Those forms intentionally share the same observed group order. Changing factor-level order can change seeded realization order even when the distribution is unchanged; that is not an invariance claimed here.

Positive and negative affine transformations `7 + b * value`, for `b = 2, -2`, are checked both as transformed input and through forwarded callback arguments. Missing values in the unrelated column must reach the callback. A separate variant replaces `B-2` with `NA`: the default mean propagates the missing value whenever B is sampled, while a callback with `na.rm = TRUE` uses B's remaining total 2, observed size 1, and mean 2. The original missing row and its copy ID still reach the callback; the bootstrap helper must not delete it.

Numerical comparisons use `testthat::expect_equal()` with tolerance `1e-12`. Support multiplicities, row/copy identities, and RNG states are checked exactly. No test asks a random sample mean to approximate the full-support mean. Existing [sampling and input-contract tests](https://github.com/DiogoRibeiro7/PharmaStatsR/blob/main/tests/testthat/test-block-bootstrap.R), including `NULL` returns and positional callback arguments, remain unchanged.

The reference verifies the stated conditional distribution, not confidence-interval coverage, adequate inference with three clusters, informative cluster-size assumptions, independence of clusters, multistage sampling, or a grouped model fitted after resampling. It introduces no production behavior, signature, or dependency change. Statistical support remains experimental.

## Interpretation

The function returns a list of `R` values from your statistic, preserving a `NULL` callback value as a list entry. It does not calculate confidence intervals, p-values, or an appropriate number of replicates for you. Cluster-level resampling is relevant when clusters are the sampled independent units; consider the sampling design, small numbers of clusters, and the statistic's behavior when some clusters are absent in a replicate. See the [family review](resampling-review.md) and [limitations](limitations.md).

R documents [how `split()` drops unused factor levels](https://stat.ethz.ch/R-manual/R-devel/library/base/html/split.html), and the [R Journal discussion of clustered resampling](https://journal.r-project.org/articles/RJ-2023-015/) describes the cluster-level cases bootstrap.

## R help

Full arguments and return values: [`pharma_block_bootstrap()`](https://github.com/DiogoRibeiro7/PharmaStatsR/blob/main/man/pharma_block_bootstrap.Rd). In an installed package, run `help("pharma_block_bootstrap", package = "PharmaStatsR")`.
