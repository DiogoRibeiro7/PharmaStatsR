# Bowker test of symmetry

`pharma_bowker_test()` tests whether paired nominal-category transitions are
symmetric across a square contingency table.

For every unordered pair of categories `i < j`, Bowker's statistic uses

\[
\frac{(n_{ij}-n_{ji})^2}{n_{ij}+n_{ji}}
\]

when `n_ij + n_ji > 0`. The full statistic is the sum over informative
off-diagonal pairs. Its degrees of freedom equal the number of such pairs.

```r
tab <- matrix(c(
  20, 8, 2,
   2,15, 5,
   1, 3,14
), 3, byrow = TRUE)

pharma_bowker_test(tab)
```

## Independent reference

For the fixed table above, the three pair contributions are

\[
\frac{(8-2)^2}{10}=\frac{18}{5},
\qquad
\frac{(2-1)^2}{3}=\frac{1}{3},
\qquad
\frac{(5-3)^2}{8}=\frac{1}{2}.
\]

Therefore

\[
X^2_B
=
\frac{18}{5}+\frac{1}{3}+\frac{1}{2}
=
\frac{133}{30}
\approx 4.4333,
\]

with 3 degrees of freedom.

The tests also verify simultaneous category-permutation invariance, transpose
invariance, the symmetric-table zero boundary, effective degrees of freedom
when some off-diagonal pairs are empty, and the K=2 identity with the
uncorrected McNemar statistic.

## Interpretation limits

Bowker's test concerns symmetry of paired nominal transitions. It is not the
Stuart-Maxwell test of marginal homogeneity, does not measure agreement, and
does not fit a transition model. Empty off-diagonal pairs contribute neither
to the statistic nor to its degrees of freedom.

## R help

Full arguments and return values:
[`pharma_bowker_test()`](https://github.com/DiogoRibeiro7/PharmaStatsR/blob/main/man/pharma_bowker_test.Rd).
