# Paired binary McNemar test

`pharma_mcnemar_test()` analyzes a paired 2×2 binary count table. Rows
represent the first condition and columns the second condition. Only the two
off-diagonal cells are used:

[
b=x_{12},qquad c=x_{21}.
]

```r
tab <- matrix(
  c(30, 12,
    4, 24),
  nrow = 2,
  byrow = TRUE
)

pharma_mcnemar_test(tab)
```

The returned `htest` object contains the asymptotic McNemar statistic and
p-value, plus `exact.p.value`, the two discordant counts, and their total.

## Independent reference

For the fixed table above, (b=12), (c=4), and there are 16 discordant
pairs. The uncorrected statistic is

[
X^2=rac{(b-c)^2}{b+c}
=rac{8^2}{16}=4.
]

With continuity correction,

[
X^2_{cc}
=
rac{(|b-c|-1)^2}{b+c}
=
rac{49}{16}
=
3.0625.
]

The asymptotic p-values use a chi-square distribution with one degree of
freedom.

Under the exact null hypothesis, conditional on (b+c=16),

[
Bsimmathrm{Binomial}(16,0.5).
]

The smaller discordant count is 4. The exact two-sided p-value is

[
2P(Ble4)
=
2rac{sum_{k=0}^{4}inom{16}{k}}{2^{16}}
=
rac{2517}{32768}
=
0.076812744140625.
]

The tests construct this finite binomial support directly rather than calling
another McNemar implementation.

Changing the diagonal concordant cells leaves every result unchanged.
Transposing the table swaps the two discordant counts but leaves the statistic
and both p-values unchanged.

## Boundaries and interpretation

With no discordant pairs there is no evidence of marginal asymmetry; the helper
returns statistic 0 and both p-values 1 rather than an undefined `0/0`.
Equal discordant counts likewise give statistic 0 and p-values 1.

McNemar's test requires genuine paired binary observations. This helper does
not establish pairing validity, address missing or unmatched pairs, model more
than two repeated binary measurements, estimate a causal treatment effect, or
replace a prespecified paired-endpoint analysis.

## R help

Full arguments and return values:
[`pharma_mcnemar_test()`](https://github.com/DiogoRibeiro7/PharmaStatsR/blob/main/man/pharma_mcnemar_test.Rd).
