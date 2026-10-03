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

## Interpretation

The function returns a list of `R` values from your statistic, preserving a `NULL` callback value as a list entry. It does not calculate confidence intervals, p-values, or an appropriate number of replicates for you. Cluster-level resampling is relevant when clusters are the sampled independent units; consider the sampling design, small numbers of clusters, and the statistic's behavior when some clusters are absent in a replicate. See the [family review](resampling-review.md) and [limitations](limitations.md).

R documents [how `split()` drops unused factor levels](https://stat.ethz.ch/R-manual/R-devel/library/base/html/split.html), and the [R Journal discussion of clustered resampling](https://journal.r-project.org/articles/RJ-2023-015/) describes the cluster-level cases bootstrap.

## R help

Full arguments and return values: [`pharma_block_bootstrap()`](https://github.com/DiogoRibeiro7/PharmaStatsR/blob/main/man/pharma_block_bootstrap.Rd). In an installed package, run `help("pharma_block_bootstrap", package = "PharmaStatsR")`.
