# Cochran–Armitage trend test

`pharma_cochran_armitage_test()` tests for a linear trend in binary event
rates across ordered groups such as increasing dose levels.

Input is a K×2 count table:

- rows: ordered groups or doses;
- column 1: events;
- column 2: non-events.

By default the row scores are (0,1,ldots,K-1). Custom scores must be finite,
strictly increasing, and supplied in the same order as the rows.

```r
tab <- cbind(
  events = c(2, 5, 9, 14),
  nonevents = c(18, 15, 11, 6)
)

pharma_cochran_armitage_test(tab)
```

## Independent reference

For four groups of size 20 with event counts (2,5,9,14), the pooled event
proportion is

[
hat p = rac{30}{80} = rac38,
qquad
hat q = rac58.
]

With scores (w=(0,1,2,3)), define

[
U = sum_i w_i(x_i-n_ihat p).
]

The fixed table gives

[
U=20.
]

The null variance is

[
V
=
hat phat q
left[
sum_i n_i w_i^2
-
rac{(sum_i n_i w_i)^2}{sum_i n_i}
ight].
]

Here

[
sum_i n_i w_i^2=280,
qquad
rac{(sum_i n_i w_i)^2}{80}=180,
]

so

[
V = rac{3}{8}rac{5}{8}(100)
= rac{375}{16}.
]

Therefore

[
Z=rac{U}{sqrt V}
=
rac{16}{sqrt{15}}
approx 4.13.
]

Two-sided and one-sided p-values use the standard normal distribution. Positive
Z means event rates tend to increase with the supplied scores.

The tests verify that adding a constant to every score or multiplying all scores
by a positive constant leaves Z unchanged. Reversing the ordered groups reverses
the sign, as does swapping event and non-event columns.

## Interpretation limits

This is an asymptotic score test for a linear trend in proportions. It does not
fit a dose-response model, estimate a clinically meaningful slope, prove
monotonicity, choose dose scores after looking at the outcome, or establish a
causal treatment effect.

Every group must contain at least one observation, and the pooled event
proportion must lie strictly between zero and one.

## R help

Full arguments and return values:
[`pharma_cochran_armitage_test()`](https://github.com/DiogoRibeiro7/PharmaStatsR/blob/main/man/pharma_cochran_armitage_test.Rd).
