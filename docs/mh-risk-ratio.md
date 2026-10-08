# Mantel-Haenszel common risk ratio

`pharma_mh_risk_ratio()` estimates a cohort-style common risk ratio across
stratified 2×2 tables.

For stratum (s), let (a,b) be event/non-event counts in row 1 and (c,d)
the corresponding counts in row 2. Define row totals (r_1=a+b),
(r_2=c+d), total (n=r_1+r_2), and total events (m_1=a+c).

The Mantel-Haenszel components are

[
R_s = rac{a r_2}{n},
qquad
S_s = rac{c r_1}{n},
qquad
T_s = rac{r_1 r_2 m_1 - acn}{n^2}.
]

Then

[
widehat{RR}_{MH}
=
rac{sum_s R_s}{sum_s S_s},
]

and the Greenland-Robins large-sample variance is

[
operatorname{Var}{log(widehat{RR}_{MH})}
=
rac{sum_s T_s}
     {(sum_s R_s)(sum_s S_s)}.
]

## Independent reference

For

```r
x <- array(0, dim = c(2, 2, 3))
x[, , 1] <- matrix(c(8, 2, 2, 8), 2, byrow = TRUE)
x[, , 2] <- matrix(c(6, 4, 3, 7), 2, byrow = TRUE)
x[, , 3] <- matrix(c(9, 1, 4, 6), 2, byrow = TRUE)

pharma_mh_risk_ratio(x)
```

the fixed components are:

- (R=(4,3,4.5)), so (sum R=11.5);
- (S=(1,1.5,2)), so (sum S=4.5);
- (T=(1.7,1.35,1.45)), so (sum T=4.5).

Therefore

[
widehat{RR}_{MH}
=
rac{11.5}{4.5}
=
rac{23}{9}
approx 2.5556,
]

and

[
operatorname{Var}{log(widehat{RR}_{MH})}
=
rac{4.5}{11.5cdot 4.5}
=
rac{2}{23}.
]

The corresponding 95% Wald interval is approximately
((1.4338, 4.5550)).

The tests also verify stratum-order invariance, reciprocal behavior under row
swapping, confidence-level handling, and undefined zero-event boundaries.

## Interpretation limits

This is a stratified cohort-style common risk ratio. It is not an odds ratio and
does not test whether stratum-specific risk ratios are homogeneous. The Wald
interval is a large-sample approximation.

## R help

Full arguments and return values:
[`pharma_mh_risk_ratio()`](https://github.com/DiogoRibeiro7/PharmaStatsR/blob/main/man/pharma_mh_risk_ratio.Rd).
