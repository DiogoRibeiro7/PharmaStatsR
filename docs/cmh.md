# Stratified Cochran–Mantel–Haenszel test

`pharma_cmh_test()` analyzes a 2×2 table observed across one or more
prespecified strata. It delegates the conditional test and common odds-ratio
confidence interval to `stats::mantelhaen.test()`, while enforcing a narrow
count-table contract.

The array orientation is explicit:

- rows: treatment/exposure groups;
- columns: binary outcome levels;
- third dimension: strata.

The reported common odds ratio compares **row 1 versus row 2** for **column 1
versus column 2**.

```r
tab <- array(0, dim = c(2, 2, 3))
tab[, , 1] <- matrix(c(12, 8, 5, 15), 2, byrow = TRUE)
tab[, , 2] <- matrix(c(20, 10, 10, 20), 2, byrow = TRUE)
tab[, , 3] <- matrix(c(8, 12, 4, 16), 2, byrow = TRUE)

pharma_cmh_test(tab, correct = FALSE)
```

## Independent reference

For each stratum (k), write

[
egin{pmatrix}
a_k & b_k\\
c_k & d_k
end{pmatrix},
qquad n_k=a_k+b_k+c_k+d_k.
]

Conditioning on the stratum margins, the expected upper-left count is

[
E(a_k)=
rac{(a_k+b_k)(a_k+c_k)}{n_k},
]

with conditional variance

[
V(a_k)=
rac{(a_k+b_k)(c_k+d_k)(a_k+c_k)(b_k+d_k)}
{n_k^2(n_k-1)}.
]

For the fixed three-stratum reference, the expectations are
(8.5,15,6), the deviations (a_k-E(a_k)) are (3.5,5,2), and

[
sum_k V(a_k)=rac{77993}{9204}.
]

Therefore the uncorrected statistic is

[
X^2_{mathrm{CMH}}
=
rac{(10.5)^2}{77993/9204}
=
rac{1014741}{77993}
approx 13.01067.
]

With the usual continuity correction,

[
X^2_{mathrm{CMH,cc}}
=
rac{(10.5-0.5)^2}{77993/9204}
=
rac{920400}{77993}
approx 11.80106.
]

The common Mantel–Haenszel odds ratio is reconstructed independently as

[
widehat{	heta}_{MH}
=
rac{sum_k a_k d_k/n_k}
{sum_k b_k c_k/n_k}
=
rac{431}{116}
approx 3.71552.
]

The tests also verify invariance to stratum order and reciprocal odds ratios
when treatment rows are swapped.

## Interpretation limits

A single common odds ratio is meaningful only if the stratum-specific effects
can reasonably be summarized together. This helper does **not** test
homogeneity of odds ratios, validate the stratification plan, establish
randomization or causal effects, address sparse-data bias, or choose strata
after seeing outcomes.

Each stratum must have positive row and column margins. Counts must be finite,
nonnegative whole numbers.

## R help

Full arguments and return values:
[`pharma_cmh_test()`](https://github.com/DiogoRibeiro7/PharmaStatsR/blob/main/man/pharma_cmh_test.Rd).
