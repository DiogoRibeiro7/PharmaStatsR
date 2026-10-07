# Fisher exact test for a 2×2 table

`pharma_fisher_test()` performs an exact conditional test for a 2×2 count
table with explicit orientation:

- rows: treatment/exposure groups;
- columns: binary outcome levels.

The returned odds ratio compares **row 1 versus row 2** for **column 1 versus
column 2**.

```r
tab <- matrix(
  c(1, 9,
    11, 3),
  nrow = 2,
  byrow = TRUE
)

pharma_fisher_test(tab)
```

The helper accepts `alternative = "two.sided"`, `"less"`, or
`"greater"` and forwards the confidence level to `stats::fisher.test()`.

## Independent exact reference

For the fixed table

[
egin{pmatrix}
1 & 9\\
11 & 3
end{pmatrix},
]

the row-1 total is 10, the column-1 total is 12, and the grand total is 24.
Conditioning on the margins, the upper-left count (A) has support
(0,ldots,10) with

[
P(A=a)
=
rac{inom{12}{a}inom{12}{10-a}}
{inom{24}{10}}.
]

At the observed value (a=1),

[
P(A=1)=rac{10}{7429}.
]

For R's two-sided Fisher rule, the exact p-value sums every support point whose
conditional probability is no larger than the observed-table probability.
Here those points are (0,1,9,10), giving

[
p_{	ext{two-sided}}
=
rac{41}{14858}
approx 0.0027594562.
]

The one-sided tails are

[
p_{	ext{less}}
=
P(Ale1)
=
rac{41}{29716},
]

and

[
p_{	ext{greater}}
=
P(Age1)
=
rac{29715}{29716}.
]

The tests enumerate this support directly with binomial coefficients; expected
p-values are not produced by another call to `fisher.test()`.

## Odds ratio

The odds-ratio estimate returned by R's Fisher test is the **conditional
maximum-likelihood estimate** under fixed margins. It is not generally equal
to the raw sample cross-product (ad/bc).

Swapping either the treatment rows or the outcome columns reverses the odds
ratio. The reference verifies reciprocal estimates and reciprocal confidence
limits while preserving the two-sided p-value.

A separate zero-cell fixture

[
egin{pmatrix}
0 & 5\\
4 & 1
end{pmatrix}
]

has a finite exact two-sided p-value (1/21) and a boundary odds-ratio estimate
of zero.

## Interpretation limits

Fisher's test conditions on the observed margins. The helper does not establish
randomization validity, causal effects, a sampling scheme that justifies fixed
margins, or a preferred odds-ratio estimand. It is intentionally restricted to
2×2 tables; larger RxC tables and Monte Carlo approximations are outside this
feature.

Counts must be finite nonnegative whole numbers with positive row and column
margins.

## R help

Full arguments and return values:
[`pharma_fisher_test()`](https://github.com/DiogoRibeiro7/PharmaStatsR/blob/main/man/pharma_fisher_test.Rd).
